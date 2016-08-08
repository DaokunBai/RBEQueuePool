//
//  RBEQueuePool.m
//  RBEQueuePool
//
//  Created by Robbie on 16/6/18.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEQueuePool.h"
#import <libkern/OSAtomic.h>

#define MAX_QUEUE_COUNT 32

static const void * const kQueueSpecificKey = &kQueueSpecificKey;

#pragma mark - C Implementation Hash Table

typedef struct hash_node_t {
    char *key;
    void *value;
    struct hash_node_t *next;
} hash_node_t;

typedef struct hash_table_t {
    uint32_t size;
    struct hash_node_t **bucket;
} hash_table_t;

static hash_table_t *table_init(uint32_t size) {
    hash_table_t *table = NULL;
    
    if ((table = calloc(1, sizeof(hash_table_t))) == NULL) {
        return NULL;
    }
    
    if ((table->bucket = calloc(size, sizeof(hash_node_t))) == NULL) {
        return NULL;
    }
    
    for (int i = 0; i < size; i++) {
        table->bucket[i] = NULL;
    }
    
    table->size = size;
    
    return table;
}

static uint32_t table_hash(hash_table_t *table, const char *key) {
    unsigned hashVal;
    
    for (hashVal = 0; *key != '\0'; key++) {
        hashVal = *key + 31 * hashVal;
    }
    
    return hashVal % table->size;
}

hash_node_t *table_find(hash_table_t *table, const char *key) {
    hash_node_t *cur = NULL;
    
    for (cur = table->bucket[table_hash(table, key)]; cur != NULL; cur = cur->next) {
        if (strcmp(key, cur->key) == 0) {
            return cur;
        }
    }
    
    return NULL;
}

static hash_node_t *table_insert(hash_table_t *table, const char *key, void *value) {
    hash_node_t *cur = NULL;
    cur = table_find(table, key);
    
    if (cur == NULL) {
        cur = calloc(1, sizeof(hash_node_t));
        if (cur == NULL || (cur->key = strdup(key)) == NULL) {
            return NULL;
        }
        uint32_t hashVal = table_hash(table, key);
        cur->value = value;
        cur->next = table->bucket[hashVal];
        table->bucket[hashVal] = cur;
    } else {
        cur->value = value;
    }
    
    return cur;
}

static void table_destory(hash_table_t *table) {
    hash_node_t *cur, *pre = NULL;
    
    for (int i = 0; i < table->size; i++) {
        cur = table->bucket[i];
        while (cur != NULL) {
            pre = cur;
            cur = cur->next;
            free(pre);
        }
    }
    
    if (table->bucket) {
        free(table->bucket);
    }
    free(table);
}

static inline qos_class_t NSQualityOfServiceToQOSClass(NSQualityOfService qos) {
    switch (qos) {
        case NSQualityOfServiceUserInteractive:
            return QOS_CLASS_USER_INTERACTIVE;
        case NSQualityOfServiceUserInitiated:
            return QOS_CLASS_USER_INITIATED;
        case NSQualityOfServiceBackground:
            return QOS_CLASS_BACKGROUND;
        case NSQualityOfServiceUtility:
            return QOS_CLASS_UTILITY;
        case NSQualityOfServiceDefault:
            return QOS_CLASS_DEFAULT;
        default:
            return QOS_CLASS_UNSPECIFIED;
    }
}

#pragma mark - CFQueuePool

typedef struct {
    const char *basicName;
    hash_table_t *hashTable;
    uint32_t basicQueueCount;
    int32_t counter;
} RBECFQueuePoolRef;

static RBECFQueuePoolRef *RBECFQueuePoolCreate(const char *basicName, int32_t basicQueueCount, CFArrayRef names, NSQualityOfService qos) {
    RBECFQueuePoolRef *pool = calloc(1, sizeof(RBECFQueuePoolRef));
    if (pool == NULL) {
        return NULL;
    }
    
    pool->basicQueueCount = basicQueueCount;
    int32_t queueCount = (uint32_t)CFArrayGetCount(names);
    
    pool->hashTable = table_init(queueCount);
    if (pool->hashTable == NULL) {
        free(pool);
        return NULL;
    }
    
    for (uint32_t i = 0; i < queueCount; i++) {
        CFStringRef cfStr = CFArrayGetValueAtIndex(names, i);
        
        const char *name = CFStringGetCStringPtr(cfStr, kCFStringEncodingUTF8);
        if (name == NULL) {
            CFIndex length = CFStringGetLength(cfStr);
            CFIndex maxSize =
            CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) + 1;
            char *buffer = (char *)malloc(maxSize);
            if (CFStringGetCString(cfStr, buffer, maxSize,
                                   kCFStringEncodingUTF8)) {
                name = buffer;
            } else {
                free(buffer);
                table_destory(pool->hashTable);
                free(pool);
                return NULL;
            }
        }
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, NSQualityOfServiceToQOSClass(qos), 0);
        dispatch_queue_t queue = dispatch_queue_create(name, attr);
        dispatch_queue_set_specific(queue, kQueueSpecificKey, (void *)cfStr, NULL);
        if (table_insert(pool->hashTable, name, (__bridge_retained void *)queue) == NULL) {
            table_destory(pool->hashTable);
            free(pool);
            return NULL;
        }
    }
    
    pool->basicName = strdup(basicName);
    
    return pool;
}

static void RBECFQueuePoolRelease(RBECFQueuePoolRef *pool) {
    if (pool->hashTable) {
        table_destory(pool->hashTable);
        pool->hashTable = NULL;
    }
    
    free(pool);
}

static void _RBECFQueuePoolGetBasicQueueName(RBECFQueuePoolRef *pool, char *name) {
    int32_t counter = OSAtomicIncrement32(&pool->counter);
    if (counter < 0) {
        counter = -counter;
    }
    
    counter = counter % pool->basicQueueCount;
    if (counter == 0) {
        counter = pool->basicQueueCount;
    }
    
    char num[10];
    strcpy(name, pool->basicName);
    strcat(name, "_");
    sprintf(num, "%d", counter);
    strcat(name, num);
}

static dispatch_queue_t _RBECFQueuePoolGetQueue(RBECFQueuePoolRef *pool, const char *name) {
    hash_node_t *node = table_find(pool->hashTable, name);
    if (node == NULL) {
        return dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL);
    }
    return (__bridge dispatch_queue_t)node->value;
}

static dispatch_queue_t RBECFQueuePoolGetBasicQueue(RBECFQueuePoolRef *pool) {
    char name[100];
    _RBECFQueuePoolGetBasicQueueName(pool, name);
    return _RBECFQueuePoolGetQueue(pool, name);
}

static dispatch_queue_t RBECFQueuePoolGetUniqueQueue(RBECFQueuePoolRef *pool, const char *name) {
    return _RBECFQueuePoolGetQueue(pool, name);
}

# pragma mark - NSQueuePool

@interface RBEQueuePool () {
    RBECFQueuePoolRef *_pool;
}

@end

@implementation RBEQueuePool

- (instancetype)initWithBasicQueueName:(NSString *)basicName uniqueQueueNameArr:(NSArray<NSString *> *)uniqueQueueNameArr qos:(NSQualityOfService)qos {
    return [self initWithBasicQueueName:basicName basicQueueCount:[NSProcessInfo processInfo].activeProcessorCount uniqueQueueNameArr:uniqueQueueNameArr qos:qos];
}

- (instancetype)initWithBasicQueueName:(NSString *)basicName basicQueueCount:(NSUInteger)basicQueueCount uniqueQueueNameArr:(NSArray<NSString *> *)uniqueQueueNameArr qos:(NSQualityOfService)qos {
    self = [super init];
    if (self) {
        NSParameterAssert(basicName.length < 97);
        
        if ((basicQueueCount == 0 && uniqueQueueNameArr.count == 0) || basicQueueCount + uniqueQueueNameArr.count > MAX_QUEUE_COUNT) {
            return nil;
        }
        
        NSMutableArray *queueNameArr = [[NSMutableArray alloc] init];
        for (NSUInteger i = 1; i <= basicQueueCount; i++) {
            [queueNameArr addObject:[NSString stringWithFormat:@"%@_%ld", basicName, (long)i]];
        }
        
        [uniqueQueueNameArr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSParameterAssert([obj isKindOfClass:[NSString class]]);
            [queueNameArr addObject:obj];
        }];
        
        _qos = qos;
        _basicQueueCount = basicQueueCount;
        _basicQueueName = basicName;
        _queueNameArr = [queueNameArr copy];
        _pool = RBECFQueuePoolCreate(basicName.UTF8String, (int32_t)basicQueueCount, (__bridge CFArrayRef)(_queueNameArr), qos);
        if (_pool == NULL) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    if (_pool) {
        RBECFQueuePoolRelease(_pool);
        _pool = NULL;
    }
}

- (dispatch_queue_t)basicQueue {
    return RBECFQueuePoolGetBasicQueue(_pool);
}

- (dispatch_queue_t)uniqueQueueWithQueueName:(NSString *)queueName {
    return RBECFQueuePoolGetUniqueQueue(_pool, queueName.UTF8String);
}

@end

@implementation RBEQueuePool (DeadLock)

- (void)dispatchSync:(dispatch_queue_t)queue deadLockSafe:(void (^)(void))block {
    CFStringRef currentRef = dispatch_get_specific(kQueueSpecificKey);
    CFStringRef dispatchRef = dispatch_queue_get_specific(queue, kQueueSpecificKey);
    if (currentRef && dispatchRef) {
        if (CFEqual(currentRef, dispatchRef)) {
            block();
        } else {
            dispatch_sync(queue, ^{
                block();
            });
        }
    } else {
        dispatch_sync(queue, ^{
            block();
        });
    }
}

@end
