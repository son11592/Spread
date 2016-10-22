//
//  SRemoteTaskManager.m
//  Spread
//
//  Created by Huy Pham on 4/15/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SRemoteTaskManager.h"

#import "SUtils.h"
#import "NSArray+Spread.h"

@interface SRemoteTaskManager ()

@property (nonatomic, strong) NSMutableArray *pendingTasks;
@property (nonatomic, strong) NSMutableArray *executingTasks;

@end

@implementation SRemoteTaskManager

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self commonInit];
    return self;
}

- (void)commonInit {
    _pendingTasks = [[NSMutableArray alloc] init];
    _executingTasks = [[NSMutableArray alloc] init];
    NSOperationQueue *queue = [[SUtils sharedInstance] operationQueue];
    [queue addObserver:self
            forKeyPath:@"operations"
               options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
               context:NULL];
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (![keyPath isEqualToString:@"operations"]) {
        return;
    }
    NSInteger old = [change[@"old"] count];
    NSInteger new = [change[@"new"] count];
    if (new < old) {
        [self processOperation];
    }
}

- (void)processOperation {
    @synchronized(_executingTasks) {
        @synchronized (_pendingTasks) {
            // There are no task in queue.
            if ([_pendingTasks count] == 0) {
                return;
            }
            NSOperationQueue *queue = [[SUtils sharedInstance] operationQueue];
            
            // Queue is max concurrent.
            if ([queue operationCount] >= [queue maxConcurrentOperationCount]) {
                return;
            }
            NSMutableArray *taskToRemove = [NSMutableArray array];
            for (SRemoteTask *pendingTask in _pendingTasks) {
                if ([self checkDequeueCondtion:pendingTask]) {
                    [_executingTasks addObject:pendingTask];
                    [taskToRemove addObject:pendingTask];
                    [self processTask:pendingTask];
                }
            }
            [_pendingTasks removeObjectsInArray:taskToRemove];
        }
    }
}

- (BOOL)checkDequeueCondtion:(SRemoteTask *)task {
    @synchronized (_executingTasks) {
        if ([_executingTasks count] == 0) {
            return YES;
        }
        NSArray *executingTasksWithKind = [_executingTasks filter:^BOOL(id element) {
            return [task isKindOfClass:[element class]];
        }];
        if ([executingTasksWithKind count] == 0) {
            return YES;
        }
        NSArray *tasks = [executingTasksWithKind filter:^BOOL(SRemoteTask *element) {
            return ![task dequeue:element];
        }];
        if ([tasks count] == 0) {
            return YES;
        }
        return NO;
    }
}

+ (void)addTask:(SRemoteTask *)task {
    NSAssert([task.class isSubclassOfClass:[SRemoteTask class]], @"Task must be SRemoteTask or sub class of SRemoteTask.");
    if (![task.class isSubclassOfClass:[SRemoteTask class]]) {
        return;
    }
    NSMutableArray *pendingTasks = [[self sharedInstance] pendingTasks];
    @synchronized (pendingTasks) {
        NSArray *tasksToRemove = [[pendingTasks
                                   filter:^BOOL(id element) {
                                       return [task isKindOfClass:[element class]];
                                   }]
                                  filter:^BOOL(id element) {
                                      return ![task enqueue:element];
                                  }];
        [pendingTasks removeObjectsInArray:tasksToRemove];
        [pendingTasks addObject:task];
        [[self sharedInstance] processOperation];
    }
}

- (void)processTask:(SRemoteTask *)task {
    [SUtils request:[task getRequestUrl]
             method:[task getMethodString]
         parameters:[task getRequestParameters]
  completionHandler:^(id response, NSError *error) {
      if (task.handler) {
          task.handler(response, error);
      }
      [_executingTasks removeObject:task];
  }];
}

@end
