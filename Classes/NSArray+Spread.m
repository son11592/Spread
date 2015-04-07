//
//  NSArray+Spread.m
//  Spread
//
//  Created by Huy Pham on 4/6/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "NSArray+Spread.h"

@implementation NSArray (Spread)

- (NSArray *)filter:(BOOL (^)(id))filter {
    
    NSMutableArray *array = [NSMutableArray array];
    for (id model in self) {
        if (filter(model)) {
            [array addObject:model];
        }
    }
    return [array mutableCopy];
}

@end
