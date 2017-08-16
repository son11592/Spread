//
//  SUtils.m
//  Spread
//
//  Created by Huy Pham on 4/9/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#define API_TIMEOUT_INTERVAL 20.0

#import "SUtils.h"
#import "Spread.h"

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

+ (NSString *)getGETParametersString:(NSDictionary *)dictionary {
    NSString *stringParameters = @"";
    if (dictionary) {
        NSArray *allKey = [dictionary allKeys];
        for (NSString *key in allKey) {
            if ([stringParameters isEqualToString:@""]) {
                stringParameters = [stringParameters stringByAppendingString:[NSString stringWithFormat:@"%@=%@",
                                                                              key, [dictionary valueForKey:key]]];
            } else {
                stringParameters = [stringParameters stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",
                                                                              key, [dictionary valueForKey:key]]];
            }
        }
    }
    return stringParameters;
}

+ (NSData *)getPOSTParameters:(NSDictionary *)dictionary {
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:NULL];
    return postdata;
}

+ (void)request:(NSString *)url
         method:(NSString *)method
     parameters:(NSDictionary *)parameters
completionHandler:(void(^)(id, NSError *))completion {
    NSURL *requestUrl = nil;
    NSString *requestMethod = [method uppercaseString];
    if (![requestMethod isEqualToString:@"GET"] &&
        ![requestMethod isEqualToString:@"POST"] &&
        ![requestMethod isEqualToString:@"PUT"] &&
        ![requestMethod isEqualToString:@"DELETE"]) {
        NSLog(@"Unsupport method %@", method);
        return;
    }
    if ([method isEqualToString:@"GET"] && parameters) {
        requestUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", url, [self getGETParametersString:parameters]]];
    } else {
        requestUrl = [NSURL URLWithString:url];
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestUrl];
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    NSDictionary *headers = [Spread getNetworkHeaders];
    for (NSString *key in [headers allKeys]) {
        NSString *value = [headers valueForKey:key];
        if (!value) {
            continue;
        }
        if (![value isEqualToString:@""]) {
            [request setValue:value
           forHTTPHeaderField:key];
        }
    }
    [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset]
   forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:requestMethod];
    if (parameters) {
        [request setHTTPBody:[self getPOSTParameters:parameters]];
    }
    [request setTimeoutInterval:API_TIMEOUT_INTERVAL];
    [NSURLConnection sendAsynchronousRequest:request queue:[[self sharedInstance] operationQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                             if (httpResponse && httpResponse.statusCode != 200) {
                               NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                                    code:httpResponse.statusCode
                                                                userInfo:NULL];
                               completion(nil, error);
                             } else if (connectionError) {
                               completion(nil, connectionError);
                             } else {
                               NSError *error;
                               NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data
                                                                                       options:NSJSONReadingAllowFragments
                                                                                         error:&error];
                               completion(jsonObj, error);
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
