//
//  SPool.m
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SPool.h"
#import "SModel.h"

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

- (NSArray *)modelSerializer:(NSArray *)objects {
    NSMutableArray *models = [NSMutableArray array];
    for (NSDictionary *object in objects) {
        id model = [[self.modelClass alloc] initWithDictionary:object];
        [models addObject:model];
    }
    return models;
}

- (id)addObject:(NSDictionary *)object {
    if (!object) return nil;
    id model = [[self.modelClass alloc] initWithDictionary:object];
    [self addModel:model];
    return model;
}

- (NSArray *)addObjects:(NSArray *)objects {
    if ([objects count] == 0) return @[];
    NSArray *dataToAdd = [self modelSerializer:objects];
    [self addModels:dataToAdd];
    return dataToAdd;
}

- (NSArray *)replaceByObjects:(NSArray *)objects {
  NSArray *dataToReplace = [self modelSerializer:objects];
  [self replaceByModels:dataToReplace];
  return dataToReplace;
}

- (id)insertObject:(NSDictionary *)object
           atIndex:(NSUInteger)index {
    if (!object) return nil;
    id model = [[self.modelClass alloc] initWithDictionary:object];
    [self insertModel:model
              atIndex:index];
    return model;
}

- (NSArray *)insertObjects:(NSArray *)objects
                 atIndexes:(NSIndexSet *)indexes {
    if ([objects count] == 0) return @[];
    NSArray *dataToAdd = [self modelSerializer:objects];
    [self insertModels:dataToAdd
             atIndexes:indexes];
    return dataToAdd;
}

- (void)addModel:(id)model {
    NSAssert([[model class] isSubclassOfClass:self.modelClass], @"Model class was not registed.");
    if (!model) return;
    [_data addObject:model];
    [self triggerForEvent:SPoolEventOnAddModel];
}

- (void)addModels:(NSArray *)models {
#ifdef DEBUG
    for (id model in models) {
        NSAssert([[model class] isSubclassOfClass:self.modelClass], @"Model class was not registed.");
    }
#endif
    if ([models count] == 0) return;
    [_data addObjectsFromArray:models];
    [self triggerForEvent:SPoolEventOnAddModel];
}

- (void)replaceByModels:(NSArray *)models {
#ifdef DEBUG
    for (id model in models) {
      NSAssert([[model class] isSubclassOfClass:self.modelClass], @"Model class was not registed.");
    }
#endif
    [_data removeAllObjects];
    [_data addObjectsFromArray:models];
    [self triggerForEvent:SPoolEventOnChange];
}

- (void)insertModels:(NSArray *)models
           atIndexes:(NSIndexSet *)indexes {
#ifdef DEBUG
    for (id model in models) {
        NSAssert([[model class] isSubclassOfClass:self.modelClass], @"Model class was not registed.");
    }
#endif
    [_data insertObjects:models
               atIndexes:indexes];
    [self triggerForEvent:SPoolEventOnAddModel];
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

- (NSArray *)diffModels:(NSArray *)models
                   keys:(NSArray *)keys {
    NSArray *result = [models filter:^BOOL(SModel *model) {
        for (SModel *element in self.allModels) {
            if ([self compareModel:model
                         withModel:element
                            byKeys:keys]) {
                return false;
            }
        }
        return true;
    }];
    return result;
}

- (NSArray *)diffObjects:(NSArray *)objects
                    keys:(NSArray *)keys {
    NSArray *models = [self modelSerializer:objects];
    return [self diffModels:models
                       keys:keys];
}

- (BOOL)compareModel:(SModel *)targetModel
           withModel:(SModel *)model
              byKeys:(NSArray *)keys {
    for (NSString *key in keys) {
        id targetModelValue = [targetModel valueForKey:key];
        id destinationModel = [model valueForKey:key];
        if ([targetModelValue respondsToSelector:@selector(isKindOfClass:)]) {
            if ([targetModelValue isKindOfClass:[NSString class]]) {
                if (![targetModelValue isEqualToString:destinationModel]) {
                    return false;
                }
            } else {
                if (targetModelValue != destinationModel) {
                    return false;
                }
            }
        }
    }
    return true;
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
    NSArray *actions = [_actions copy];
    for (SPoolAction *action in actions) {
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
    NSArray *reactions = [_reactions copy];
    for (SPoolReaction *reaction in reactions) {
        if (reaction.event == SPoolEventOnChange
            || reaction.event == event) {
            reaction.reaction([_data copy]);
        }
    }
}

- (void)triggerTargetForEvent:(SPoolEvent)event {
    NSMutableArray *dataToRemove = [NSMutableArray array];
    NSArray *actions = [_actions copy];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        for (SPoolAction *action in actions) {
            if (action.target) {
                if (action.event == SPoolEventOnChange
                    || action.event == event) {
                    ((void (*)(id, SEL, id))[action.target methodForSelector:action.selector])(action.target,
                                                                                               action.selector, self);
                }
            } else {
                [dataToRemove addObject:action];
            }
        }
        [_actions removeObjectsInArray:dataToRemove];
    }];
}

- (void)removeTarget:(id)target
            selector:(SEL)selector
             onEvent:(SPoolEvent)event {
    NSMutableArray *dataToRemove = [NSMutableArray array];
    NSArray *actions = [_actions copy];
    for (SPoolAction *poolAction in actions) {
        if ([poolAction compareWithTarget:target
                                 selector:selector
                                    event:event]) {
            [dataToRemove addObject:poolAction];
        }
    }
    [_actions removeObjectsInArray:dataToRemove];
}

- (void)removeModelMatch:(BOOL (^)(id))filter {
    NSArray *objectToRemove = [_data filter:filter];
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
