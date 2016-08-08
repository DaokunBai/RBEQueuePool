//
//  ViewController.m
//  RBEQueuePoolDemo
//
//  Created by Robbie on 16/8/5.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "ViewController.h"
#import "RBEQueuePool.h"

#define DeadLockEnable 0

@interface ViewController ()

@property (nonatomic, strong) RBEQueuePool *interactiveQueuePool;

@property (nonatomic, strong) RBEQueuePool *defaultQueuePool;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    for (int i = 0; i < 10; i++) {
        dispatch_async([self.interactiveQueuePool basicQueue], ^{
            NSLog(@"On different basic queue");
        });
    }
    
    dispatch_async([self.interactiveQueuePool uniqueQueueWithQueueName:@"demo_database_queue"], ^{
        NSLog(@"On demo_database_queue");
    });
    
    dispatch_async([self.interactiveQueuePool uniqueQueueWithQueueName:@"demo_network_queue"], ^{
        NSLog(@"On demo_network_queue");
    });
    
    dispatch_async([self.interactiveQueuePool uniqueQueueWithQueueName:@"demo_ui_render_queue"], ^{
        NSLog(@"On demo_ui_render_queue");
    });
    
    dispatch_async([self.interactiveQueuePool uniqueQueueWithQueueName:@"demo_not_register_queue"], ^{
        NSLog(@"On demo_not_registe_queue");
    });
    
    dispatch_async([self.interactiveQueuePool uniqueQueueWithQueueName:@"demo_not_registe_queue"], ^{
        dispatch_sync_rbeQueuePool(self.interactiveQueuePool, @"demo_database_queue", ^() {
            NSLog(@"async not deadlock on unique queue");
        });
    });

    dispatch_sync_rbeQueuePool(self.interactiveQueuePool, @"demo_database_queue", ^{
        dispatch_sync_rbeQueuePool(self.interactiveQueuePool, @"demo_database_queue", ^{
            dispatch_sync_rbeQueuePool(self.interactiveQueuePool, @"demo_database_queue", ^{
                NSLog(@"sync not deadlock on unique queue");
            })
        })
    })
        
#if DeadLockEnable
    dispatch_sync_rbeQueuePool(self.interactiveQueuePool, @"demo_database_queue", ^{
        dispatch_sync_rbeQueuePool(self.interactiveQueuePool, @"demo_network_queue", ^{
            dispatch_sync_rbeQueuePool(self.interactiveQueuePool, @"demo_database_queue", ^{
                NSLog(@"definitely deadLock");
            })
        })
    })
#endif
}

- (RBEQueuePool *)interactiveQueuePool {
    if (!_interactiveQueuePool) {
        _interactiveQueuePool = [[RBEQueuePool alloc] initWithBasicQueueName:@"demo_interactive_basic_queue" uniqueQueueNameArr:@[@"demo_database_queue", @"demo_network_queue", @"demo_ui_render_queue"] qos:NSQualityOfServiceUserInteractive];
    }
    return _interactiveQueuePool;
}

- (RBEQueuePool *)defaultQueuePool {
    if (!_defaultQueuePool) {
        _defaultQueuePool = [[RBEQueuePool alloc] initWithBasicQueueName:@"demo_default_basic_queue" basicQueueCount:5 uniqueQueueNameArr:nil qos:NSQualityOfServiceDefault];
    }
    return _defaultQueuePool;
}
@end
