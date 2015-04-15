//
//  SRemoteTask.h
//  Spread
//
//  Created by Huy Pham on 4/15/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SModel.h"

typedef NS_ENUM(NSInteger, SRemoteTaskMethod){
  SRemoteTaskMethodGET,
  SRemoteTaskMethodPOST,
  SRemoteTaskMethodPUT,
  SRemoteTaskMethodDELETE
};

@interface SRemoteTask : NSObject

@property (nonatomic, copy) void (^handler)(id, NSError *);
@property (nonatomic, strong) SModel *model;
@property (nonatomic) SRemoteTaskMethod method;

- (BOOL)dequeueCondtion:(SRemoteTask *)executingTask;
- (BOOL)enqueueCondtion:(SRemoteTask *)penddingTask;

- (void)addHanlder:(void (^)(id, NSError *))handler;
- (NSString *)getRequestUrl;
- (NSDictionary *)getRequestParameters;
- (NSString *)getMethodString;

@end
