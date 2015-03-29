//
//  SPool.h
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPool : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) Class modelClass;

/**
 *  Add object to pool.
 *
 *  @param object object to add.
 *
 *  @return object to add.
 */
- (id)addObject:(NSDictionary *)object;

/**
 *  Remove an object to pool.
 *
 *  @param object object to remove.
 */
- (void)removeObject:(id)object;

/**
 *  Remove multi objects in pool.
 *
 *  @param objects array of objects to remove.
 */
- (void)removeObjects:(NSArray *)objects;

/**
 *  Get all object in from.
 *
 *  @return array of objects.
 */
- (NSArray *)allObjects;

/**
 *  Return object match filter.
 *
 *  @param filter filer condition.
 *
 *  @return array of objects.
 */
- (NSArray *)filter:(BOOL (^)(id))filter;

/**
 *  Remove object matched filter.
 *
 *  @param filter fitler condition.
 */
- (void)removeObjectMatch:(BOOL (^)(id))filter;

@end
