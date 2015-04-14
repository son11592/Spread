//
//  SPool.h
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

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
 *  @param object Object to add.
 *
 *  @return       Object added.
 */
- (id)addObject:(NSDictionary *)object;

/**
 *  Add multi object to pool;
 *
 *  @param objects Array of object.
 *
 *  @return        Array of objects added.
 */
- (NSArray *)addObjects:(NSArray *)objects;

/**
 *  Remove an object to pool.
 *
 *  @param object Object to remove.
 */
- (void)removeObject:(id)object;

/**
 *  Remove multi objects in pool.
 *
 *  @param objects Array of objects to remove.
 */
- (void)removeObjects:(NSArray *)objects;

/**
 *  Get all object in from.
 *
 *  @return Array of objects.
 */
- (NSArray *)allObjects;

/**
 *  Return object match filter.
 *
 *  @param filter Filer condition.
 *
 *  @return       Array of objects.
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
 *  @param event    Event description.
 *  @param reaction Pool reaction.
 */
- (void)onEvent:(SPoolEvent)event
       reaction:(void(^)(NSArray *data))reaction;

/**
 *  Add target for event, automatic delete action when target become nil.
 *
 *  @param target   Object target.
 *  @param selector Selector for event.
 *  @param event    Event description.
 */
- (void)addTarget:(id)target
         selector:(SEL)selector
          onEvent:(SPoolEvent)event;

/**
 *  Remove target for event.
 *
 *  @param target   Object target..
 *  @param selector Selector for event.
 *  @param event    Event description.
 */
- (void)removeTarget:(id)target
            selector:(SEL)selector
             onEvent:(SPoolEvent)event;

@end
