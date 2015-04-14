//
//  SRemoteTask.h
//  Spread
//
//  Created by Huy Pham on 4/15/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SModel.h"

@interface SRemoteTask : NSObject

@property (nonatomic, copy) void (^handler)(id, NSError *);
@property (nonatomic, strong) SModel *model;

- (BOOL)dequeueCondtion:(SRemoteTask *)executingTask;
- (BOOL)enqueueCondtion:(SRemoteTask *)penddingTask;

- (void)addHanlder:(void (^)(id, NSError *))handler;
- (NSString *)getRequestUrl;
- (NSDictionary *)getRequestParameters;

@end
