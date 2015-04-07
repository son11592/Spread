//
//  SPool.h
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSArray+Spread.h"

/**
 *  Spool event.
 */
typedef NS_ENUM(NSInteger, SPoolEvent){
    /**
     *  Pool calls event when initial data.
     */
    SPoolEventOnInitModel,
    /**
     * Pool calls event when add new model.
     */
    SPoolEventOnAddModel,
    /**
     *  Pool calls event when remove a model.
     */
    SPoolEventOnRemoveModel,
    /**
     *  Pool calls event when data is changed.
     */
    SPoolEventOnChange
};

@interface SPool : NSObject

/**
 *  Pool identifier.
 */
@property (nonatomic, copy) NSString *identifier;

/**
 *  Registered class.
 */
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
- (void)onEvent:(SPoolEvent)event
       reaction:(void(^)(NSArray *data))react;

/**
 *  Add target for event, automatic delete action when target become nil.
 *
 *  @param target     object target.
 *  @param action     a selector event.
 *  @param poolEvent  event type.
 */
- (void)addTarget:(id)target
           action:(SEL)action
     forPoolEvent:(SPoolEvent)poolEvent;

/**
 *  Remove target for event.
 *
 *  @param target     object target..
 *  @param action     a selector event.
 *  @param poolEvent  event type.
 */
- (void)removeTarget:(id)target
              action:(SEL)action
        forPoolEvent:(SPoolEvent)poolEvent;

/**
 *  Array of objects.
 */
@property (nonatomic, strong, readonly) NSMutableArray *data;

@end
