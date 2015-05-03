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

@property (nonatomic) BOOL keep;

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

- (id)insertObject:(NSDictionary *)object
           atIndex:(NSUInteger)index;

- (NSArray *)insertObjects:(NSArray *)objects
                 atIndexes:(NSIndexSet *)indexes;

- (void)addModel:(id)model;

- (void)addModels:(NSArray *)models;

- (void)insertModel:(id)model
            atIndex:(NSInteger)index;

- (void)insertModels:(NSArray *)models
           atIndexes:(NSIndexSet *)indexes;

/**
 *  Remove an model from pool.
 *
 *  @param model Model to remove.
 */
- (void)removeModel:(id)model;

/**
 *  Remove multi models in pool.
 *
 *  @param models Array of models to remove.
 */
- (void)removeModels:(NSArray *)models;

/**
 *  Remove all models in pool.
 */
- (void)removeAllModels;

/**
 *  Get all model in from.
 *
 *  @return Array of models.
 */
- (NSArray *)allModels;
- (NSArray *)diffModels:(NSArray *)models keys:(NSArray *)keys;
- (NSArray *)diffObjects:(NSArray *)objects keys:(NSArray *)keys;

/**
 *  Remove model matched filter.
 *
 *  @param filter fitler condition.
 */
- (void)removeModelMatch:(BOOL (^)(id))filter;

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
