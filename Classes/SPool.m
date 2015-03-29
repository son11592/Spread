//
//  SPool.m
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SPool.h"

@implementation SPool {
    
    NSMutableArray *_models;
}

+ (instancetype)sharedInstance {
    
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    return self;
}

- (NSMutableArray *)models {
    
    @synchronized(self) {
        if (!_models) {
            _models = [NSMutableArray array];
        }
    }
    return _models;
}

- (id)addObject:(NSDictionary *)object {
    
    id model = [[self.modelClass alloc] initWithDictionary:object];
    [[self models] addObject:model];
    return model;
}

- (NSArray *)allObjects {
    
    return [self models];
}

- (void)removeObject:(id)object {
    
    [[self models] removeObject:object];
}

- (void)removeObjects:(NSArray *)objects {
    
    [[self models] removeObjectsInArray:objects];
}

- (NSArray *)filter:(BOOL (^)(id))filter {
    
    NSMutableArray *array = [NSMutableArray array];
    for (id model in [self allObjects]) {
        if (filter(model)) {
            [array addObject:model];
        }
    }
    return array;
}

- (void)removeObjectMatch:(BOOL (^)(id))filter {
    
    NSArray *objectToRemove = [self filter:filter];
    [[self models] removeObjectsInArray:objectToRemove];
}

@end
