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
@property (nonatomic, copy) void (^react)(NSArray *);

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
    
    _reactions = [NSMutableArray array];
    _actions = [NSMutableArray array];
    _data = [NSMutableArray array];
}

- (NSMutableArray *)reactions {
    
    return _reactions;
}

- (id)addObject:(NSDictionary *)object {
    
    id model = [[self.modelClass alloc] initWithDictionary:object];
    [self.data addObject:model];
    if ([self.data count] == 1) {
        [self triggerForEvent:SPoolEventOnInitModel];
    }
    return model;
}

- (NSArray *)addObjects:(NSArray *)objects {
    
    NSMutableArray *dataToAdd = [NSMutableArray array];
    for (NSDictionary *object in objects) {
        id model = [[self.modelClass alloc] initWithDictionary:object];
        [dataToAdd addObject:model];
    }
    [self.data addObjectsFromArray:dataToAdd];
    [self triggerForEvent:SPoolEventOnAddModel];
    return dataToAdd;
}

- (NSArray *)allObjects {
    
    return [self data];
}

- (void)removeObject:(id)object {
    
    [self.data removeObject:object];
    [self triggerForEvent:SPoolEventOnRemoveModel];
}

- (void)removeObjects:(NSArray *)objects {
    
    [self.data removeObjectsInArray:objects];
    [self triggerForEvent:SPoolEventOnRemoveModel];
}

- (NSArray *)filter:(BOOL (^)(id))filter {
    
    NSMutableArray *array = [NSMutableArray array];
    for (id model in [self allObjects]) {
        if (filter(model)) {
            [array addObject:model];
        }
    }
    return array;
}

- (void)onEvent:(SPoolEvent)event
       reaction:(void(^)(NSArray *data))react {
    
    SPoolReaction *reaction = [[SPoolReaction alloc] init];
    reaction.event = event;
    reaction.react = react;
    [_reactions addObject:reaction];
}

- (void)addTarget:(id)target
           action:(SEL)action
     forPoolEvent:(SPoolEvent)poolEvent {
    
    SPoolAction *poolAction = [[SPoolAction alloc] init];
    poolAction.target = target;
    poolAction.selector = action;
    poolAction.event = poolEvent;
    
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
            reaction.react(self.data);
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
              action:(SEL)action
        forPoolEvent:(SPoolEvent)poolEvent {
    
    NSMutableArray *dataToRemove = [NSMutableArray array];
    for (SPoolAction *poolAction in _actions) {
        if ([poolAction compareWithTarget:target
                                 selector:action
                                    event:poolEvent]) {
            [dataToRemove addObject:poolAction];
        }
    }
    [_actions removeObjectsInArray:dataToRemove];
}

- (void)removeObjectMatch:(BOOL (^)(id))filter {
    
    NSArray *objectToRemove = [self filter:filter];
    [self.data removeObjectsInArray:objectToRemove];
}

- (void)dealloc {
    
    [_actions removeAllObjects];
    [_reactions removeAllObjects];
#ifdef DEBUG
    NSLog(@"Pool release.");
#endif
}

@end
