# RBEQueuePool(En)

RBEQueuePool is a library that helps you managing your multithreads. It also decreases the expense brought by multithreads, and take advantage of them. Many enlightening ideas were referenced from [YYDispatchQueuePool](https://github.com/ibireme/YYDispatchQueuePool).

The aim of RBEQueuePool architecture is to getting more close the native Apple libraries. The implementation of RBEQueuePool includes three levels: C level, CF level and NS level.

The purpose of multithread is process concurrently, which means that fully take advantage of the multiple core of CPU. But more threads doest not mean better for multithreads, since every single threads introduces more expense. And when the difference of concurrent processing efficiency and expense brought by multithread is less than the series processing efficiency, the multithread lose its meaning. 

The expenses brought by frequent context switch between overmuch threads, and their creation/destruction can both be avoided via RBEQueuePool. 

### Feature

- Reduce expenses of creating and destroy thread.
- Control the maximum amount of thread concurrent.
- Manage universal queue.
- Avoid deadlock in most scenario.


### Requirements

iOS8.0+

### Installation

Cocopod

------

### Usage

RBEQueuePool provide two type of queue, one is the basic queue, the other is the unique queue. If you do not care which queue block execute on, the basic queue is your choice. If you intend to execute block on specific queue, the unique queue is your choice. RBEQueuePool could create 32 queue maximum including the basic queue and the unique queue. You could write following code to init RBEQueuePool:

```objective-c
    RBEQueuePool *interactiveQueuePool = [[RBEQueuePool alloc] 
      initWithBasicQueueName:@"demo_interactive_basic_queue"
             basicQueueCount:5
          uniqueQueueNameArr:@[@"demo_database_queue",                                                                  
                               @"demo_network_queue",
                               @"demo_ui_render_queue"]
                         qos:NSQualityOfServiceUserInteractive];
```

Or init this way, the amount of the basic queue equal to the count of processor in default.

```objective-c
    RBEQueuePool *interactiveQueuePool = [[RBEQueuePool alloc] 
      initWithBasicQueueName:@"demo_interactive_basic_queue"
          uniqueQueueNameArr:@[@"demo_database_queue",                                                                  
                               @"demo_network_queue",
                               @"demo_ui_render_queue"]
                         qos:NSQualityOfServiceUserInteractive];
```

The last parameters you provide is the priority of the queue. If you intend to employ different priority queue,  you should init multiple RBEQueuePool.

RBEQueuePool only create serial queue, to restrict the maximum concurrent thread. If you employ RBEQueuePool, strongly suggest you do not create queue by calling dispatch_get_global_queue or dispatch_queue_create in your project.

You could fetch queue by following code:

```objective-c
[interactiveQueuePool basicQueue]

[interactiveQueuePool uniqueQueueWithQueueName:@"demo_database_queue"]
```

If try to fetch a unregister queue, RBEQueuePool will create a queue for error tolerant.

If you intend to call dispatch_sync, you could call dispatch_sync_rbeQueuePool for replacement, to avoid deadlock in most scenario.

```objective-c
    dispatch_async([interactiveQueuePool uniqueQueueWithQueueName:@"demo_not_registe_queue"], ^{
        dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^() {
            NSLog(@"async not deadlock on unique queue");
        });
    });

    dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
        dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
            dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
                NSLog(@"sync not deadlock on unique queue");
            })
        })
    })
```

Although it may still deadlock, the following code could lead to deadlock.

```objective-c
    dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
        dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_network_queue", ^{
            dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
                NSLog(@"definitely deadLock");
            })
        })
    })
```

------

Above code also demonstrate in demo.

Most of all, have fun!



# RBEQueuePool(中文)

RBEQueuePool是个帮助你很好管理多线程的库。它还可以降低多线程带来的开销，充分利用多线程。它从[YYDispatchQueuePool](https://github.com/ibireme/YYDispatchQueuePool)借鉴了些很有启发的思想。

RBEQueuePool架构的宗旨是，更加接近Apple原生的库。RBEQueuePool实现为三个层面，C层面、CF层面和NS层面。

多线程的目的是并发处理，同一时间计算机处理多个任务。但是多线程不代表线程越多就越好，每个线程都会带来开销，线程越多就会有越多个开销，当并发处理效率 - 多线程带来的开销 < 串行处理效率时，多线程就失去了意义。

过多的线程带来的频繁上下文切换的开销和线程频繁创建、消亡的开销都可以由RBEQueuePool来避免。

### 主要功能

- 降低线程创建和消亡带来的开销。
- 控制线程最大并发量。
- 管理全局通用队列。
- 避免大部分由dispatch_sync带来的死锁。


### 支持

iOS8.0+

### 安装

Cocopod

------

### 使用

RBEQueuePool提供一种basic queue和另一种unique queue。当你不关心block在那个queue上执行，你可以使用basic queue，当你希望一些block都在一个特定的queue上执行，你可以使用unique queue。RBEQueuePool可以创建的basic queue和unique queue最多为32个。你可以这样创建：

```objective-c
    RBEQueuePool *interactiveQueuePool = [[RBEQueuePool alloc] 
      initWithBasicQueueName:@"demo_interactive_basic_queue"
             basicQueueCount:5
          uniqueQueueNameArr:@[@"demo_database_queue",                                                                  
                               @"demo_network_queue",
                               @"demo_ui_render_queue"]
                         qos:NSQualityOfServiceUserInteractive];
```

或者这样创建，这样BasicQueue的数量默认为你现在CPU的核数。

```objective-c
    RBEQueuePool *interactiveQueuePool = [[RBEQueuePool alloc] 
      initWithBasicQueueName:@"demo_interactive_basic_queue"
          uniqueQueueNameArr:@[@"demo_database_queue",                                                                  
                               @"demo_network_queue",
                               @"demo_ui_render_queue"]
                         qos:NSQualityOfServiceUserInteractive];
```

最后一个参数是你提供的队列的优先级。如果想要不同优先级的queue，必须创建多个RBEQueuePool。

RBEQueuePool创建的queue都是serial，以限制最大并发的线程数。如果你使用了RBEQueuePool，建议在项目中不要使用dispatch_get_global_queue或dispatch_queue_create来获得queue了。

你可以这样取得queue:

```objective-c
[interactiveQueuePool basicQueue]

[interactiveQueuePool uniqueQueueWithQueueName:@"demo_database_queue"]
```

如果你取得的queue是未注册的queue，RBEQueuePool会为你创建一个queue以做容错处理。

如果想要调用dispatch_sync，可以使用*dispatch_sync_rbeQueuePool*宏来避免大部分情况下的死锁。

```objective-c
    dispatch_async([interactiveQueuePool uniqueQueueWithQueueName:@"demo_not_registe_queue"], ^{
        dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^() {
            NSLog(@"async not deadlock on unique queue");
        });
    });

    dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
        dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
            dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
                NSLog(@"sync not deadlock on unique queue");
            })
        })
    })
```

但仍是有死锁的情况，比如下面代码仍会引起死锁。

```objective-c
    dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
        dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_network_queue", ^{
            dispatch_sync_rbeQueuePool(interactiveQueuePool, @"demo_database_queue", ^{
                NSLog(@"definitely deadLock");
            })
        })
    })
```

------

所有代码都可以在Demo中找到。

最重要的，玩的愉快！