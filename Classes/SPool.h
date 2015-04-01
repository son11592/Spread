//
//  SPool.h
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SPoolEvent) {
    SPoolEventOnInitModel,
    SPoolEventOnAddModel,
    SPoolEventOnRemoveModel,
    SPoolEventOnChange
};

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
 *  Add multi object to pool;
 *
 *  @param objects array of object.
 *
 *  @return array of objects added.
 */
- (NSArray *)addObjects:(NSArray *)objects;

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

/**
 *  Reaction when pool change.
 *
 *  @param event event type.
 *  @param react reaction.
 */
- (void)reactOnChange:(SPoolEvent)event
                react:(void(^)(NSArray *data))react;

/**
 *  Array of objects.
 */
@property (nonatomic, strong, readonly) NSMutableArray *data;

@end
