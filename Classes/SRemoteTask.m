//
//  SRemoteTask.m
//  Spread
//
//  Created by Huy Pham on 4/15/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SRemoteTask.h"

@implementation SRemoteTask

- (NSString *)getRequestUrl {
    
    return @"";
}

- (NSDictionary *)getRequestParameters {
    
    return _parameters;
}

- (void)addHanlder:(void (^)(id, NSError *))handler {
  
    _handler = handler;
}

- (BOOL)dequeueCondtion:(SRemoteTask *)executingTask {
    
    return YES;
}

- (BOOL)enqueueCondtion:(SRemoteTask *)penddingTask {
    
    return YES;
}

@end
