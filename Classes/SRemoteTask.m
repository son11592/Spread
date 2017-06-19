//
//  SRemoteTask.m
//  Spread
//
//  Created by Huy Pham on 4/15/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SRemoteTask.h"

@implementation SRemoteTask

- (instancetype)init {
    self =[super init];
    if (!self) {
        return nil;
    }
    [self commonInit];
    return self;
}

- (void)commonInit {
    _method = SRemoteTaskMethodPOST;
}

- (NSString *)getRequestUrl {
    return @"";
}

- (NSDictionary *)getRequestParameters {
    return nil;
}

- (NSString *)getMethodString {
    switch (self.method) {
        case SRemoteTaskMethodGET:
            return @"GET";
        case SRemoteTaskMethodPOST:
            return @"POST";
        case SRemoteTaskMethodPUT:
            return @"PUT";
        case SRemoteTaskMethodDELETE:
            return @"DELETE";
        default:
            return @"";
    }
}

- (void)addHanlder:(void (^)(id, NSError * _Nullable))handler {
    _handler = handler;
}


- (BOOL)dequeue:(SRemoteTask *)executingTask {
    return YES;
}

- (BOOL)enqueue:(SRemoteTask *)penddingTask {
    return YES;
}

@end
