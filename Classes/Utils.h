//
//  Utils.h
//  Spread
//
//  Created by Huy Pham on 4/9/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

@property (nonatomic, strong) NSOperationQueue *operationQueue;

+ (instancetype)sharedInstance;

+ (void)getRequest:(NSString *)url
        parameters:(NSDictionary *)parameters
 completionHandler:(void(^)(id response, NSError *error))completion;

+ (NSDictionary *)getDataFrom:(NSDictionary *)data
                  WithKeyPath:(NSString *)keyPath;

@end
