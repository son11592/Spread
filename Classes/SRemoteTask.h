//
//  SRemoteTask.h
//  Spread
//
//  Created by Huy Pham on 4/15/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  SRemoteTask method description.
 */
typedef NS_ENUM(NSInteger, SRemoteTaskMethod){
    /**
     *  Get method.
     */
    SRemoteTaskMethodGET,
    /**
     *  Post method.
     */
    SRemoteTaskMethodPOST,
    /**
     *  Put method.
     */
    SRemoteTaskMethodPUT,
    /**
     *  Delete method.
     */
    SRemoteTaskMethodDELETE
};

@interface SRemoteTask : NSObject

// Task handler when completed.
@property (nonatomic, copy) void (^handler)(id, NSError * _Nullable);

// Task network method.
@property (nonatomic) SRemoteTaskMethod method;

/**
 *  Dequeue condition for task object.
 *
 *  @param executingTask Executing task object in queue.
 *  @return task will dequeue or not.
 */
- (BOOL)dequeue:(SRemoteTask *)executingTask;

/**
 *  Enqueue condition for task object.
 *
 *  @param penddingTask Pendding task object in queue.
 *  @return task in pending queue will remove or not.
 */
- (BOOL)enqueue:(SRemoteTask *)penddingTask;

- (void)addHanlder:(void (^)(id, NSError * _Nullable))handler;
- (NSString *)getRequestUrl;
- (NSDictionary *)getRequestParameters;
- (NSString *)getMethodString;

@end

NS_ASSUME_NONNULL_END
