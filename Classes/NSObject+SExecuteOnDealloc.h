//
//  NSObject+SExecuteOnDealloc.h
//  Spread
//
//  Created by Huy Pham on 3/27/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (SExecuteOnDealloc)

- (void *)performBlockOnDealloc:(void (^)(id))aBlock;
- (void)cancelDeallocBlockWithKey:(void *)blockKey;

@end
