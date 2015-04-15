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

@property (nonatomic, strong) NSMutableArray *penddingTasks;
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
    
    _penddingTasks = [[NSMutableArray alloc] init];
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
    
    // There are no task in queue.
    if ([_penddingTasks count] == 0) {
        return;
    }
    NSOperationQueue *queue = [[SUtils sharedInstance] operationQueue];
    
    // Queue is max concurrent.
    if ([queue operationCount] >= [queue maxConcurrentOperationCount]) {
        return;
    }
    for (SRemoteTask *penddingTask in [_penddingTasks copy]) {
        if ([self checkDequeueCondtion:penddingTask]) {
            [_executingTasks addObject:penddingTask];
            [_penddingTasks removeObject:penddingTask];
            [self processTask:penddingTask];
        }
    }
}

- (BOOL)checkDequeueCondtion:(SRemoteTask *)task {
    
    NSArray *tasks = [[_executingTasks copy] filter:^BOOL(SRemoteTask *element) {
        return [task isKindOfClass:[element class]] && ![task dequeueCondtion:element];
    }];
    
    if ([tasks count] == 0) {
        return YES;
    }
    return NO;
}

+ (void)addTask:(SRemoteTask *)task {
    
    NSMutableArray *penddingTasks = [[self sharedInstance] penddingTasks];
    for (SRemoteTask *penddingTask in [penddingTasks copy]) {
        if ([task isKindOfClass:[penddingTask class]] && ![task enqueueCondtion:penddingTask]) {
            [penddingTasks removeObject:penddingTask];
        }
    }
    [penddingTasks addObject:task];
    [[self sharedInstance] processOperation];
}

- (void)processTask:(SRemoteTask *)task {
    
    [SUtils request:[task getRequestUrl]
             method:@"POST"
         parameters:[task getRequestParameters]
  completionHandler:^(id response, NSError *error) {
      if (task.handler) {
          task.handler(response, error);
      }
      [_executingTasks removeObject:task];
  }];
}

@end
