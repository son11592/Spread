//
//  SUtils.m
//  Spread
//
//  Created by Huy Pham on 4/9/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#define API_TIMEOUT_INTERVAL 20.0

#import "SUtils.h"

@implementation SUtils

- (instancetype)init {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    [self commonInit];
    return self;
}

- (void)commonInit {
    
    _operationQueue = [[NSOperationQueue alloc] init];
    [_operationQueue setMaxConcurrentOperationCount:10];
}

+ (instancetype)sharedInstance {
    
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)request:(NSString *)url
         method:(NSString *)method
     parameters:(NSDictionary *)parameters
completionHandler:(void(^)(id, NSError *))completion {
    
    // Create url with parameteres.
    NSString *stringParameters = @"";
    if (parameters) {
        NSArray *allKey = [parameters allKeys];
        for (NSString *key in allKey) {
            if ([stringParameters isEqualToString:@""]) {
                stringParameters = [stringParameters stringByAppendingString:[NSString stringWithFormat:@"%@=%@", key, [parameters valueForKey:key]]];
            } else {
                stringParameters = [stringParameters stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", key, [parameters valueForKey:key]]];
            }
        }
    }
    
    // Make request.
    NSURL *requestUrl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestUrl];
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:method];
    [request setTimeoutInterval:API_TIMEOUT_INTERVAL];
    [NSURLConnection sendAsynchronousRequest:request queue:[[self sharedInstance] operationQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   completion(nil, connectionError);
                               } else {
                                   NSError *error;
                                   NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data
                                                                                           options:NSJSONReadingAllowFragments
                                                                                             error:&error];
                                   completion(jsonObj, nil);
                               }
                           }];
}

+ (NSDictionary *)getDataFrom:(NSDictionary *)data
                  WithKeyPath:(NSString *)keyPath {
    
    if (!keyPath || [keyPath isEqualToString:@""]) {
        return data;
    }
    NSArray *arrayOfKeyPath = [keyPath componentsSeparatedByString:@"/"];
    NSDictionary *value = data;
    for (NSString *path in arrayOfKeyPath) {
        value = [value valueForKey:path];
    }
    return value;
}

@end
