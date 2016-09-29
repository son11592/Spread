//
//  NSArray+Spread.h
//  Spread
//
//  Created by Huy Pham on 4/6/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Spread)

- (NSArray *)filter:(BOOL (^)(id))filter;

@end

NS_ASSUME_NONNULL_END
