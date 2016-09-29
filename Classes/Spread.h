//
//  Spread.h
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SModel.h"
#import "SPool.h"

NS_ASSUME_NONNULL_BEGIN

@interface Spread : NSObject

/**
 *  Return shared instance of Spread.
 *
 *  @return Spread shared instance.
 */
+ (instancetype)sharedInstance;

+ (void)setNetworkHeader:(NSDictionary *)headers;

+ (NSDictionary *)getNetworkHeaders;

/**
 *  Register class for pools.
 *
 *  @param modelClass  Class for coder.
 *  @param identifiers Array list of pools identifier.
 */
+ (SPool *)registerClass:(Class)modelClass
       forPoolIdentifier:(NSString *)identifier;

+ (SPool *)registerClass:(Class)modelClass
       forPoolIdentifier:(NSString *)identifier
                    keep:(BOOL)keep;

/**
 *  Remove a pool and class register from memory.
 *
 *  @param pool              Pool identifier.
 */
+ (void)removePoolWithIdentifier:(NSString *)identifier;

/**
 *  Register event for pools with array of identifiers.
 *
 *  @param event           Event identifier.
 *  @param poolIdentifiers Array of pools indetifier.
 *  @param action          Action handler.
 */
+ (void)registerEvent:(NSString *)event
      poolIdentifiers:(NSArray *)poolIdentifiers
               action:(void (^)(id, SPool *))action;

/**
 *  Remove event of pools.
 *
 *  @param event           Event identifier.
 *  @param poolIdentifiers Array of pools identiriers.
 */
+ (void)removeEvent:(NSString *)event
    poolIdentifiers:(NSArray *)poolIdentifiers;

/**
 *  Remove event of pools.
 *
 *  @param event Event identifier.
 */
+ (void)removeEvent:(NSString *)event;

/**
 *  Remove all event of pools.
 */
+ (void)removeAllEvent;

/**
 *  Get pool istance with identifier.
 *
 *  @param identifier Identifier of pool.
 *
 *  @return           Pool object.
 */
+ (SPool *)getPool:(NSString *)identifier;

/**
 *  Add an object to pool.
 *
 *  @param object     Object to add.
 *  @param identifier Pool identifier.
 *
 *  @return           Spread model.
 */
+ (SModel *)addObject:(NSDictionary *)object
               toPool:(NSString *)identifier;

/**
 *  Add multi objecto to pool.
 *
 *  @param objects    Array of objects.
 *  @param identifier Pool identifier.
 *
 *  @return           Array of obejcts added.
 */
+ (NSArray *)addObjects:(NSArray *)objects
                 toPool:(NSString *)identifier;

+ (SModel *)insertObject:(NSDictionary *)object
                 atIndex:(NSInteger)index
                  toPool:(NSString *)identifier;

+ (NSArray *)insertObjects:(NSArray *)objects
                 atIndexes:(NSIndexSet *)indexes
                    toPool:(NSString *)identifier;

+ (void)addModel:(id)model
          toPool:(NSString *)identifier;

+ (void)addModels:(NSArray *)models
           toPool:(NSString *)identifier;

+ (void)insertModel:(id)model
            atIndex:(NSInteger)index
             toPool:(NSString *)identifier;

+ (void)insertModels:(NSArray *)models
           atIndexes:(NSIndexSet *)indexes
              toPool:(NSString *)identifier;

/**
 *  Remove an object from pool with identifier.
 *
 *  @param object     Object to remove.
 *  @param identifier Pool identifer.
 */
+ (void)removeModel:(id)model
           fromPool:(NSString *)identifier;

/**
 *  Remove multi object in pool.
 *
 *  @param objects    Array of objects.
 *  @param identifier Pool identifier.
 */
+ (void)removeModels:(NSArray *)models
            fromPool:(NSString *)identifier;

/**
 *  Trigger event and send event to every pool had registed.
 *
 *  @param event Event identifier.
 *  @param value Value parameters.
 */
+ (void)outEvent:(NSString *)event
           value:(id)value;

/**
 *  Set maximum number of task (fetch model/interaction...) can execting at the same time.
 *
 *  @param maxConcurrentOperationCount Number of operation executing in background.
 */
+ (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount;

+ (void)setCapacity:(NSInteger)capacity;

@end

NS_ASSUME_NONNULL_END
