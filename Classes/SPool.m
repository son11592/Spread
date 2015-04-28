//
//  SPool.m
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SPool.h"

@interface SPoolReaction : NSObject

@property (nonatomic) SPoolEvent event;
@property (nonatomic, copy) void (^reaction)(NSArray *);

@end

@implementation SPoolReaction

@end

@interface SPoolAction : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic) SEL selector;
@property (nonatomic) SPoolEvent event;

- (BOOL)compareWith:(SPoolAction *)action;
- (BOOL)compareWithTarget:(id)target
                 selector:(SEL)selector
                    event:(SPoolEvent)event;

@end

@implementation SPoolAction

- (BOOL)compareWith:(SPoolAction *)action {
    
    return [self compareWithTarget:action.target
                          selector:action.selector
                             event:action.event];
}

- (BOOL)compareWithTarget:(id)target
                 selector:(SEL)selector
                    event:(SPoolEvent)event {
    
    if ([self.target isEqual:target]
        && self.selector == selector
        && self.event == event) {
        return YES;
    }
    return NO;
}

@end

@implementation SPool {
    
    // Store callback reaction.
    NSMutableArray *_reactions;
    
    // Store action with target.
    NSMutableArray *_actions;
    
    // Store pool's data.
    NSMutableArray *_data;
    
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
    [self commonInit];
    return self;
}

- (void)commonInit {
    
    _keep = NO;
    _reactions = [NSMutableArray array];
    _actions = [NSMutableArray array];
    _data = [NSMutableArray array];
}

- (NSMutableArray *)reactions {
    
    return _reactions;
}

- (id)addObject:(NSDictionary *)object {
    
    id model = [[self.modelClass alloc] initWithDictionary:object];
    [self addModel:model];
    return model;
}

- (NSArray *)addObjects:(NSArray *)objects {
    
    NSMutableArray *dataToAdd = [NSMutableArray array];
    for (NSDictionary *object in objects) {
        id model = [[self.modelClass alloc] initWithDictionary:object];
        [dataToAdd addObject:model];
    }
    [self addModels:dataToAdd];
    return dataToAdd;
}

- (id)insertObject:(NSDictionary *)object
           atIndex:(NSUInteger)index {
    
    id model = [[self.modelClass alloc] initWithDictionary:object];
    [self insertModel:model
              atIndex:index];
    return model;
}

- (NSArray *)insertObjects:(NSArray *)objects
                 atIndexes:(NSIndexSet *)indexes {
    
    NSMutableArray *dataToAdd = [NSMutableArray array];
    for (NSDictionary *object in objects) {
        id model = [[self.modelClass alloc] initWithDictionary:object];
        [dataToAdd addObject:model];
    }
    [self insertModels:dataToAdd
             atIndexes:indexes];
    return dataToAdd;
}

- (void)addModel:(id)model {
    
    NSAssert([[model class] isSubclassOfClass:self.modelClass], @"Model class was not registed.");
    [_data addObject:model];
    [self triggerForEvent:SPoolEventOnAddModel];
}

- (void)addModels:(NSArray *)models {
    
    for (id model in models) {
        NSAssert([[model class] isSubclassOfClass:self.modelClass], @"Model class was not registed.");
    }
    [_data addObjectsFromArray:models];
    [self triggerForEvent:SPoolEventOnAddModel];
}

- (void)insertModels:(NSArray *)models
          atIndexes:(NSIndexSet *)indexes {
    
    for (id model in models) {
        NSAssert([[model class] isSubclassOfClass:self.modelClass], @"Model class was not registed.");
    }
    [_data insertObjects:models
               atIndexes:indexes];
}

- (void)insertModel:(id)model
            atIndex:(NSInteger)index {
    
    NSAssert([[model class] isSubclassOfClass:self.modelClass], @"Model class was not registed.");
    [_data insertObject:model
                atIndex:index];
    [self triggerForEvent:SPoolEventOnAddModel];
}

- (NSArray *)allModels {
    
    return [_data copy];
}

- (void)removeModel:(id)model {
    
    [_data removeObject:model];
    [self triggerForEvent:SPoolEventOnRemoveModel];
}

- (void)removeModels:(NSArray *)models {
    
    [_data removeObjectsInArray:models];
    [self triggerForEvent:SPoolEventOnRemoveModel];
}

- (void)removeAllModels {
    
    [_data removeAllObjects];
    [self triggerForEvent:SPoolEventOnRemoveModel];
}

- (NSArray *)filter:(BOOL (^)(id))filter {
    
    NSMutableArray *array = [NSMutableArray array];
    for (id model in [self allModels]) {
        if (filter(model)) {
            [array addObject:model];
        }
    }
    return array;
}

- (void)onEvent:(SPoolEvent)event
       reaction:(void(^)(NSArray *data))reaction {
    
    SPoolReaction *poolReaction = [[SPoolReaction alloc] init];
    poolReaction.event = event;
    poolReaction.reaction = reaction;
    [_reactions addObject:poolReaction];
}

- (void)addTarget:(id)target
         selector:(SEL)selector
          onEvent:(SPoolEvent)event {
    
    SPoolAction *poolAction = [[SPoolAction alloc] init];
    poolAction.target = target;
    poolAction.selector = selector;
    poolAction.event = event;
    
    for (SPoolAction *action in _actions) {
        if ([poolAction compareWith:action] ) {
            return;
        }
    }
    [_actions addObject:poolAction];
}

- (void)triggerForEvent:(SPoolEvent)event {
    
    [self triggerReactionsForEvent:event];
    [self triggerTargetForEvent:event];
}

- (void)triggerReactionsForEvent:(SPoolEvent)event {
    
    for (SPoolReaction *reaction in [self reactions]) {
        if (reaction.event == SPoolEventOnChange
            || reaction.event == event) {
            reaction.reaction([_data copy]);
        }
    }
}

- (void)triggerTargetForEvent:(SPoolEvent)event {
    
    NSMutableArray *dataToRemove = [NSMutableArray array];
    for (SPoolAction *action in _actions) {
        if (!action.target) {
            [dataToRemove addObject:action];
        } else {
            if (action.event == SPoolEventOnChange
                || action.event == event) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSThread detachNewThreadSelector:action.selector
                                             toTarget:action.target
                                           withObject:self];
                });
            }
        }
    }
    [_actions removeObjectsInArray:dataToRemove];
}

- (void)removeTarget:(id)target
            selector:(SEL)selector
             onEvent:(SPoolEvent)event {
    
    NSMutableArray *dataToRemove = [NSMutableArray array];
    for (SPoolAction *poolAction in _actions) {
        if ([poolAction compareWithTarget:target
                                 selector:selector
                                    event:event]) {
            [dataToRemove addObject:poolAction];
        }
    }
    [_actions removeObjectsInArray:dataToRemove];
}

- (void)removeModelMatch:(BOOL (^)(id))filter {
    
    NSArray *objectToRemove = [self filter:filter];
    [_data removeObjectsInArray:objectToRemove];
}

- (void)dealloc {
    
    [_actions removeAllObjects];
    [_reactions removeAllObjects];
#ifdef DEBUG
    NSLog(@"Pool release.");
#endif
}

@end
