//
//  NSObject+SExecuteOnDealloc.m
//  Spread
//
//  Created by Huy Pham on 3/27/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+SExecuteOnDealloc.h"

@interface SExecuteOnDeallocInternalObject : NSObject

@property(nonatomic, copy) void (^block)(id);
@property(nonatomic, assign) __unsafe_unretained id obj;

- (id)initWithBlock:(void (^)(id))aBlock;

@end

@implementation SExecuteOnDeallocInternalObject {
    
    void(^block)(id);
}
@synthesize block;

- (id)initWithBlock:(void (^)(id))aBlock
{
    self = [super init];
    if (!self) {
        return nil;
    }
    block = [aBlock copy];
    return self;
}

- (void)dealloc {
    
    if (block) {
        block(_obj);
    }
}
@end

@implementation NSObject (SFExecuteOnDealloc)

- (void *)performBlockOnDealloc:(void (^)(id))aBlock {

    SExecuteOnDeallocInternalObject *internalObject = [[SExecuteOnDeallocInternalObject alloc] initWithBlock:aBlock];
    internalObject.obj = self;
    objc_setAssociatedObject(self, (__bridge const void *)(internalObject), internalObject, OBJC_ASSOCIATION_RETAIN);
    return (__bridge void *)(internalObject);
}

- (void)cancelDeallocBlockWithKey:(void *)blockKey {
    
    SExecuteOnDeallocInternalObject *internalObject = objc_getAssociatedObject(self, blockKey);
    internalObject.block = nil;
    objc_setAssociatedObject(self, blockKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

@end
