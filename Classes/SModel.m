//
//  SModel.m
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

static void * const SPreadContext = (void*)&SPreadContext;

#import <UIKit/UIKit.h>
#import "SModel.h"
#import "SUtils.h"
#import <objc/runtime.h>

// Magic, do not touch.
static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            NSString *name = [[NSString alloc] initWithBytes:attribute + 1
                                                      length:strlen(attribute) - 1
                                                    encoding:NSASCIIStringEncoding];
            
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            NSString *name = [[NSString alloc] initWithBytes:attribute + 3
                                                      length:strlen(attribute) - 4
                                                    encoding:NSASCIIStringEncoding];
            
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
    }
    return "";
}

@interface SModelReaction : NSObject

@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic) SModelEvent event;
@property (nonatomic, copy) void (^react)(id, id);

@end

@implementation SModelReaction

@end

@interface SModelAction : NSObject

@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic) SModelEvent event;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL selector;

@end

@implementation SModelAction

@end

@interface SModel()

@property (nonatomic, getter=isFetching) BOOL fetching;
@property (nonatomic, getter=isInitiated) BOOL initiated;

@end

@implementation SModel {
    
    // Store callback reaction.
    NSMutableArray *_reactions;
    
    // Store action with target.
    NSMutableArray *_actions;
    
    // Store keyobserver.
    NSMutableArray *_keyPaths;
    
    // Store attributes and type.
    NSMutableDictionary *_attributes;
}

// Lazy initial array to store reaction.
- (NSMutableArray *)reactions {
    @synchronized(self) {
        if (!_reactions) {
            _reactions = [NSMutableArray array];
        }
    }
    return _reactions;
}

// Lazy initial array to store action.
- (NSMutableArray *)actions {
    @synchronized(self) {
        if (!_actions) {
            _actions = [NSMutableArray array];
        }
    }
    return _actions;
}

- (NSMutableArray *)keyPaths {
    @synchronized(self) {
        if (!_keyPaths) {
            _keyPaths = [NSMutableArray array];
        }
    }
    return _keyPaths;
}


- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self commonInit];
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        [self initData:@{}];
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@:", NSStringFromClass(self.class)]);
        if ([self respondsToSelector:selector]) {
            ((void (*)(id, SEL, id))[self methodForSelector:selector])(self, selector, dictionary);
        }
        return self;
    }
    [self initData:dictionary];
    return self;
}

- (void)commonInit {
    _actions = nil;
    _reactions = nil;
    _fetching = NO;
    _initiated = NO;
    _attributes = [NSMutableDictionary dictionary];
}

// Return name tripped underscore
- (NSString *)getPropertyNameStrippedUnderscore:(NSString *)property {
    if (!property) {
        return nil;
    }
    if ([property length] == 0) {
        return @"";
    }
    if ([property characterAtIndex:0] == '_') {
        return [property substringFromIndex:1];
    }
    return property;
}

- (void)initData:(NSDictionary *)dictionary {
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for(int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if (propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithCString:propName
                                                        encoding:NSUTF8StringEncoding];
            NSString *propertyType = [NSString stringWithCString:propType
                                                        encoding:NSUTF8StringEncoding];
            NSString *propertyNameStrippedUnderscore = [self getPropertyNameStrippedUnderscore:propertyName];
            [_attributes setValue:propertyType forKey:propertyNameStrippedUnderscore];
            id instanceType = [NSClassFromString(propertyType) alloc];
            id value = [dictionary valueForKey:propertyNameStrippedUnderscore];
            if (value && value != [NSNull null]) {
                if ([instanceType respondsToSelector:@selector(initWithDictionary:)]) {
                    [self setValue:[instanceType initWithDictionary:value] forKey:propertyName];
                } else if ([instanceType respondsToSelector:@selector(initWithArray:)]) {
                    [self setValue:[instanceType initWithArray:value] forKey:propertyName];
                } else {
                    [self setValue:value forKey:propertyName];
                }
            } else {
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@", propertyName]);
                if ([self respondsToSelector:selector]) {
                    ((void (*)(id, SEL))[self methodForSelector:selector])(self, selector);
                } else {
                    if ([instanceType respondsToSelector:@selector(initWithDictionary:)]) {
                        [self setValue:[instanceType initWithDictionary:@{}] forKey:propertyName];
                    } else if ([instanceType respondsToSelector:@selector(init)]) {
                        [self setValue:[instanceType init] forKey:propertyName];
                    }
                }
            }
        }
    }
    free(properties);
    _initiated = YES;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for(int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        NSString *propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
        id value = [self valueForKey:propertyName];
        if (value) {
            NSString *propertyNameStrippedUnderscore = [self getPropertyNameStrippedUnderscore:propertyName];
            if ([[value class] isSubclassOfClass:[SModel class]]) {
                [mutableDictionary setObject:[value toDictionary]
                                      forKey:propertyNameStrippedUnderscore];
            } else if ([value isKindOfClass:[NSArray class]]) {
                [mutableDictionary setObject:[self arraySerializer:value]
                                      forKey:propertyNameStrippedUnderscore];
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                [mutableDictionary setObject:[self dictionarySerializer:value]
                                      forKey:propertyNameStrippedUnderscore];
            } else {
                [mutableDictionary setValue:[self valueSerializer:value
                                                              key:propertyNameStrippedUnderscore]
                                     forKey:propertyNameStrippedUnderscore];
            }
        }
    }
    free(properties);
    return [mutableDictionary copy];
}

- (NSDictionary *)dictionarySerializer:(NSDictionary *)dictionary {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    for (NSString *key in [dictionary allKeys]) {
        id value = [dictionary valueForKey:key];
        if ([[value class] isSubclassOfClass:[SModel class]]) {
            [mutableDictionary setObject:[value toDictionary]
                                  forKey:key];
        } else if ([value isKindOfClass:[NSArray class]]){
            [mutableDictionary setObject:[self arraySerializer:value]
                                  forKey:key];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [mutableDictionary setObject:[self dictionarySerializer:value]
                                  forKey:key];
        } else {
            [mutableDictionary setObject:[self valueSerializer:value
                                                           key:key]
                                  forKey:key];
        }
    }
    return [mutableDictionary copy];
}

- (NSArray *)arraySerializer:(NSArray *)array {
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (id value in array) {
        if ([[value class] isSubclassOfClass:[SModel class]]) {
            [mutableArray addObject:[value toDictionary]];
        } else if ([value isKindOfClass:[NSArray class]]){
            [mutableArray addObject:[self arraySerializer:value]];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [mutableArray addObject:[self dictionarySerializer:value]];
        } else {
            [mutableArray addObject:value];
        }
    }
    return [mutableArray copy];
}

- (id)valueSerializer:(id)value key:(NSString *)key {
    NSString *type  = [_attributes valueForKey:key];
    if ([type isEqualToString:@"q"]) {
        NSInteger integerValue = [value integerValue];
        return @(integerValue);
    }
    if ([type isEqualToString:@"Q"]) {
        NSUInteger uintegerValue = [value integerValue];
        return @(uintegerValue);
    }
    
    if ([type isEqualToString:@"B"]) {
        BOOL boolValue = [value boolValue];
        return @(boolValue);
    }
    
    if ([type isEqualToString:@"C"]) {
        Boolean boolValue = [value boolValue];
        return @(boolValue);
    }
    
    if ([type isEqualToString:@"d"]) {
        double floatValue = [value floatValue];
        return @(floatValue);
    }
    
    if ([type isEqualToString:@"{CGSize=dd}"]) {
        CGSize size = [value CGSizeValue];
        NSMutableDictionary *sizeDictionary = [NSMutableDictionary dictionary];
        [sizeDictionary setValue:@(size.width) forKey:@"width"];
        [sizeDictionary setValue:@(size.height) forKey:@"height"];
        return [sizeDictionary copy];
    }
    
    if ([type isEqualToString:@"{CGRect={CGPoint=dd}{CGSize=dd}}"]) {
        CGRect rect = [value CGRectValue];
        NSMutableDictionary *rectDictionary = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *sizeDictionary = [NSMutableDictionary dictionary];
        [sizeDictionary setValue:@(rect.size.width) forKey:@"width"];
        [sizeDictionary setValue:@(rect.size.height) forKey:@"height"];
        
        NSMutableDictionary *originDictionary = [NSMutableDictionary dictionary];
        [originDictionary setValue:@(rect.origin.x) forKey:@"x"];
        [originDictionary setValue:@(rect.origin.y) forKey:@"y"];
        
        [rectDictionary setValue:[sizeDictionary copy] forKey:@"size"];
        [rectDictionary setValue:[originDictionary copy] forKey:@"origin"];
        return [rectDictionary copy];
    }
    
    if ([type isEqualToString:@"{CGPoint=dd}"]) {
        CGPoint point = [value CGPointValue];
        NSMutableDictionary *pointDictionary = [NSMutableDictionary dictionary];
        [pointDictionary setValue:@(point.x) forKey:@"x"];
        [pointDictionary setValue:@(point.y) forKey:@"y"];
        return [pointDictionary copy];
    }
    
    if ([type isEqualToString:@"NSString"]) {
        return value;
    }
    
    // Add more value serializer here.
    
    return value;
}

// HELPER FUNCTION.

// Check keys path existed
- (BOOL)keyPathExisted:(NSString *)keyPath {
    NSArray *keyPaths = [_keyPaths copy];
    for (NSString *key in keyPaths) {
        if ([key isEqualToString:keyPath]) {
            return YES;
        }
    }
    return NO;
}

- (void)addKeyPath:(NSString *)keyPath {
    [[self keyPaths] addObject:[keyPath copy]];
}

- (void)removeKeyPath:(NSString *)keyPath {
    NSArray *keyPaths = [_keyPaths copy];
    NSMutableArray *keysToDelete = [NSMutableArray array];
    for (NSString *key in keyPaths) {
        if ([key isEqualToString:keyPath]) {
            [keysToDelete addObject:key];
        }
    }
    [_keyPaths removeObjectsInArray:keysToDelete];
}

// Get reaction of property on event.
- (NSArray *)getReactionsOfProperty:(NSString *)property
                            onEvent:(SModelEvent)event {
    NSMutableArray *reactions = [NSMutableArray array];
    NSArray *allReactions = [_reactions copy];
    for (SModelReaction *reaction in allReactions) {
        if ([reaction.keyPath isEqualToString:property]
            && reaction.event == event) {
            [reactions addObject:reaction];
        }
    }
    return reactions;
}

// Get reactions of property.
- (NSArray *)getReactionsOfProperty:(NSString *)property {
    NSMutableArray *reactions = [NSMutableArray array];
    NSArray *allReactions = [_reactions copy];
    for (SModelReaction *reaction in allReactions) {
        if ([reaction.keyPath isEqualToString:property]) {
            [reactions addObject:reaction];
        }
    }
    return reactions;
}

- (NSArray *)getActionsOfProperty:(NSString *)property
                           target:(id)target
                         selector:(SEL)selector
                          onEvent:(SModelEvent)event {
    NSMutableArray *actions = [NSMutableArray array];
    NSArray *allActions = [_actions copy];
    for (SModelAction *action in allActions) {
        if ([action.keyPath isEqualToString:property]
            && [action.target isEqual:target]
            && action.selector == selector
            && action.event == event) {
            [actions addObject:action];
        }
    }
    return actions;
}

- (NSArray *)getActionsOfProperty:(NSString *)property
                           target:(id)target
                         selector:(SEL)selector {
    NSMutableArray *actions = [NSMutableArray array];
    NSArray *allActions = [_actions copy];
    for (SModelAction *action in allActions) {
        if ([action.keyPath isEqualToString:property]
            && [action.target isEqual:target]
            && action.selector == selector) {
            [actions addObject:action];
        }
    }
    return actions;
}

- (NSArray *)getActionsOfProperty:(NSString *)property
                           target:(id)target {
    NSMutableArray *actions = [NSMutableArray array];
    NSArray *allActions = [_actions copy];
    for (SModelAction *action in allActions) {
        if ([action.keyPath isEqualToString:property]
            && [action.target isEqual:target]) {
            [actions addObject:action];
        }
    }
    return actions;
}

- (NSArray *)getActionsOfProperty:(NSString *)property
                          onEvent:(SModelEvent)event {
    NSMutableArray *actions = [NSMutableArray array];
    NSArray *allActions = [_actions copy];
    for (SModelAction *action in allActions) {
        if ([action.keyPath isEqualToString:property]
            && action.event == event) {
            [actions addObject:action];
        }
    }
    return actions;
}

// Get action of property.
- (NSArray *)getActionsOfProperty:(NSString *)property {
    NSMutableArray *actions = [NSMutableArray array];
    NSArray *allActions = [_actions copy];
    for (SModelAction *action in allActions) {
        if ([action.keyPath isEqualToString:property]) {
            [actions addObject:action];
        }
    }
    return actions;
}

- (void)registerObserverForKeyPath:(NSString *)keyPath {
    if (![self keyPathExisted:keyPath]) {
        @try {
            @synchronized(self) {
                [self addKeyPath:keyPath];
                [self addObserver:self
                       forKeyPath:keyPath
                          options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                          context:SPreadContext];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"[Register] Exception: %@", exception);
        }
    }
}

- (void)removeObserverForKeyPath:(NSString *)keyPath {
    if ([self keyPathExisted:keyPath]) {
        @try {
            @synchronized(self) {
                [self removeKeyPath:keyPath];
                [self removeObserver:self
                          forKeyPath:keyPath
                             context:SPreadContext];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"[Remove action] Exception: %@", exception);
        }
    }
}

- (void)removeAllObservers {
    @synchronized(self) {
        NSArray *keyPaths = [_keyPaths copy];
        for (NSString *keyPath in keyPaths) {
            @try {
                [self removeObserver:self
                          forKeyPath:keyPath
                             context:SPreadContext];
            }
            @catch (NSException *exception) {
                NSLog(@"[Remove action] Exception: %@", exception);
            }
        }
    }
}

- (void)removeActions:(NSArray *)actions
   observerForKeyPath:(NSString *)keyPath {
    @synchronized(self) {
        NSInteger observerCount = [[self getActionsOfProperty:keyPath] count] +
        [[self getReactionsOfProperty:keyPath] count];
        if (observerCount == 0) return;
        [_actions removeObjectsInArray:actions];
        [self removeObserverForKeyPath:keyPath];
    }
}

- (void)removeReactions:(NSArray *)reactions
     observerForKeyPath:(NSString *)keyPath {
    @synchronized(self) {
        NSInteger observerCount = [[self getActionsOfProperty:keyPath] count] +
        [[self getReactionsOfProperty:keyPath] count];
        if (observerCount == 0) return;
        [_reactions removeObjectsInArray:reactions];
        [self removeObserverForKeyPath:keyPath];
    }
}

// IMPLEMENT
- (void)property:(NSString *)property
         onEvent:(SModelEvent)event
        reaction:(void (^)(id, id))reaction {
    [self registerObserverForKeyPath:property];
    SModelReaction *modelReaction = [[SModelReaction alloc] init];
    modelReaction.keyPath = property;
    modelReaction.react = reaction;
    modelReaction.event = event;
    [[self reactions] addObject:modelReaction];
}

- (void)property:(NSString *)property
          target:(id)target
        selector:(SEL)selector
         onEvent:(SModelEvent)event {
    if ([[self getActionsOfProperty:property
                             target:target
                           selector:selector
                            onEvent:event] count] > 0) {
#ifdef DEBUG
        NSLog(@"Duplicated register keyPath: %@", property);
#endif
        return;
    }
    [self registerObserverForKeyPath:property];
    SModelAction *modelAction = [[SModelAction alloc] init];
    modelAction.keyPath = property;
    modelAction.target = target;
    modelAction.selector = selector;
    modelAction.event = event;
    [[self actions] addObject:modelAction];
}

- (void)properties:(NSArray *)properties
           onEvent:(SModelEvent)event
          reaction:(void (^)(id, id))reaction {
    for (NSString *property in properties) {
        [self property:property
               onEvent:event
              reaction:reaction];
    }
}

- (void)properties:(NSArray *)properties
            target:(id)target
          selector:(SEL)selector
           onEvent:(SModelEvent)event {
    for (NSString *property in properties) {
        [self property:property
                target:target
              selector:selector
               onEvent:event];
    }
}

- (void)removeReactionsForProperty:(NSString *)property
                           onEvent:(SModelEvent)event {
    NSArray *reactions = [self getReactionsOfProperty:property
                                              onEvent:event];
    if ([reactions count] == 0) return;
    [self removeReactions:reactions
       observerForKeyPath:property];
}

- (void)removeReactionsForProperty:(NSString *)property {
    NSArray *reactions = [self getReactionsOfProperty:property];
    if ([reactions count] == 0) return;
    [self removeReactions:reactions
       observerForKeyPath:property];
}

- (void)removeReactionsForProperties:(NSArray *)properties
                             onEvent:(SModelEvent)event {
    for (NSString *property in properties) {
        [self removeReactionsForProperty:property
                                 onEvent:event];
    }
}

- (void)removeReactionsForProperties:(NSArray *)properties {
    for (NSString *property in properties) {
        [self removeReactionsForProperty:property];
    }
}

- (void)removeAllReactions {
    while ([_reactions count] > 0) {
        SModelReaction *reaction = [_reactions firstObject];
        if (reaction) {
            [self removeReactionsForProperty:reaction.keyPath];
        }
    }
}

- (void)removeActionsForProperty:(NSString *)property
                          target:(id)target
                        selector:(SEL)selector
                         onEvent:(SModelEvent)event {
    NSArray *actions = [self getActionsOfProperty:property
                                           target:target
                                         selector:selector
                                          onEvent:event];
    if ([actions count] == 0) return;
    [self removeActions:actions
     observerForKeyPath:property];
}

- (void)removeActionsForProperty:(NSString *)property
                          target:(id)target {
    NSArray *actions = [self getActionsOfProperty:property
                                           target:target];
    if ([actions count] == 0) return;
    [self removeActions:actions
     observerForKeyPath:property];
}

- (void)removeActionsForProperty:(NSString *)property {
    NSArray *actions = [self getActionsOfProperty:property];
    if ([actions count] == 0) return;
    [self removeActions:actions
     observerForKeyPath:property];
}

- (void)removeActionsForProperties:(NSArray *)properties
                            target:(id)target
                          selector:(SEL)selector
                           onEvent:(SModelEvent)event {
    for (NSString *property in properties) {
        [self removeActionsForProperty:property
                                target:target
                              selector:selector
                               onEvent:event];
    }
}

- (void)removeActionsForProperties:(NSArray *)properties
                            target:(id)target {
    for (NSString *property in properties) {
        [self removeActionsForProperty:property
                                target:target];
    }
}

- (void)removeActionsForProperties:(NSArray *)properties {
    for (NSString *property in properties) {
        [self removeActionsForProperty:property];
    }
}

- (void)removeAllActions {
    while ([_actions count] > 0) {
        SModelAction *action = [_actions firstObject];
        if (action) {
            [self removeActionsForProperty:action.keyPath];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    id oldValue = change[@"old"];
    id newValue = change[@"new"];
    SModelEvent event = SModelEventOnChange;
    NSArray *reactions = [self getReactionsOfProperty:keyPath
                                              onEvent:event];
    for (SModelReaction *reaction in reactions) {
        reaction.react(oldValue, newValue);
    }
    
    // Automatic delete action when target become nil.
    NSMutableArray *actionsToDelete = [NSMutableArray array];
    NSArray *actions = [self getActionsOfProperty:keyPath
                                          onEvent:event];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        for (SModelAction *action in actions) {
            if (action.target) {
                ((void (*)(id, SEL))[action.target methodForSelector:action.selector])(action.target,
                                                                                       action.selector);
            } else {
                [actionsToDelete addObject:action];
            }
        }
        for (SModelAction *action in actionsToDelete) {
            [self removeActionsForProperty:action.keyPath
                                    target:action.target];
        }
    }];
}

- (void)fetchInBackground {
    [self fetchInBackground:nil];
}

- (void)fetchInBackground:(void (^)(id, NSError *))completion {
    if (self.isFetching) {
        return;
    }
    _fetching = YES;
    __weak SModel *weakSelf = self;
    [SUtils request:[self getSourceUrl]
             method:[self getSourceMethod]
         parameters:nil
  completionHandler:^(id response, NSError *error) {
      _fetching = NO;
      NSDictionary *data = [SUtils getDataFrom:response
                                   WithKeyPath:[weakSelf getSourceKeyPath]];
      if (data) {
          [weakSelf initData:data];
      }
      if (completion) {
          completion(data, error);
      }
  }];
}

- (NSString *)getSourceKeyPath {
    return @"";
}

- (NSString *)getSourceUrl {
    return @"";
}

- (NSString *)getSourceMethod {
    return @"GET";
}

- (BOOL)isInitiated {
    return _initiated;
}

- (BOOL)isFetching {
    return _fetching;
}

- (void)dealloc {
    [self removeAllObservers];
}

@end
