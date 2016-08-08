//
//  RBEQueuePool.h
//  RBEQueuePool
//
//  Created by Robbie on 16/6/18.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 This QueuelPool Framework do two things in general. First is holding initialized thread, to decrease thread initialize and destory resource consumption. Second is controling maximum concurrent thread amount in a 'way', to decrease thread context switch resource consumption. why is in a 'way'. It is impossible to maximum control concurrent thread at run time. Thus, to control maximum initialized thread is a compromising way.
 */

/**
 all queue of queue pool is serial queue, no need to call dispatch_get_global_queue after using this framwork.
 */

/**
 basicQueue is like a global default queue.
 uniqueQueue is like a specific queue to do specific things.
 */

/**
 meant to prevent dispatch_sync deadLock, but it can not prevent more than two level dispatch_sync deadLock
 for instance:
 dispatch_sync_rbeQueuePool(pool, @"test_queue_a", ^{
    dispatch_sync_rbeQueuePool(pool, @"test_queue_b", ^{
       dispatch_sync_rbeQueuePool(pool, @"test_queue_a", ^{
          NSLog(@"definitely deadLock");
       })
    })
 })
 */

#define dispatch_sync_rbeQueuePool(pool, uniqueQueueName, block)\
[pool dispatchSync:[pool uniqueQueueWithQueueName:uniqueQueueName] deadLockSafe:block];

NS_ASSUME_NONNULL_BEGIN

@interface RBEQueuePool : NSObject

@property (assign, nonatomic, readonly) NSQualityOfService qos;
@property (assign, nonatomic, readonly) NSUInteger basicQueueCount;
@property (nullable, strong, nonatomic, readonly) NSString *basicQueueName;
@property (nullable, strong, nonatomic, readonly) NSArray *queueNameArr;

- (instancetype)init NS_UNAVAILABLE;

//init with default basic queue amount
- (instancetype)initWithBasicQueueName:(nullable NSString *)basicName uniqueQueueNameArr:(nullable NSArray<NSString *> *)uniqueQueueNameArr qos:(NSQualityOfService)qos;

- (instancetype)initWithBasicQueueName:(nullable NSString *)basicName basicQueueCount:(NSUInteger)basicQueueCount uniqueQueueNameArr:(nullable NSArray<NSString *> *)uniqueQueueNameArr qos:(NSQualityOfService)qos;

- (nonnull dispatch_queue_t)basicQueue;

- (nonnull dispatch_queue_t)uniqueQueueWithQueueName:(nonnull NSString *)queueName;

@end

@interface RBEQueuePool (DeadLock)

- (void)dispatchSync:(nonnull dispatch_queue_t)queue deadLockSafe:(nonnull void(^)(void))block;

@end

NS_ASSUME_NONNULL_END