//
//  SModel.m
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

static void * SPreadContext = &SPreadContext;

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

@property (nonatomic, copy) NSString *sourceUrl;
@property (nonatomic, copy) NSString *sourceKeyPath;
@property (nonatomic, getter=isFetching) BOOL fetching;
@property (nonatomic, getter=isInitiated) BOOL initiated;

@end

@implementation SModel {
    
    // Store callback reaction.
    NSMutableArray *_reactions;
    
    // Store action with target.
    NSMutableArray *_actions;
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


- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self commonInit];
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@:", NSStringFromClass(self.class)]);
        if ([self respondsToSelector:selector]) {
            ((void (*)(id, SEL, id))[self methodForSelector:selector])(self, selector, dictionary);
        }
        [self initData:@{}];
        return self;
    }
    [self initData:dictionary];
    return self;
}

- (void)commonInit {
    _sourceKeyPath = @"";
    _sourceUrl = nil;
    _fetching = NO;
    _initiated = NO;
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
            id instanceType = [NSClassFromString(propertyType) alloc];
            id value = [dictionary valueForKey:[self getPropertyNameStrippedUnderscore:propertyName]];
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
                    if ([instanceType respondsToSelector:@selector(init)]) {
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
                [mutableDictionary setObject:[self arraySerialization:value]
                                      forKey:propertyNameStrippedUnderscore];
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                [mutableDictionary setObject:[self dictionarySerialization:value]
                                      forKey:propertyNameStrippedUnderscore];
            } else {
                [mutableDictionary setValue:value
                                     forKey:propertyNameStrippedUnderscore];
            }
        }
    }
    free(properties);
    return [mutableDictionary copy];
}

- (NSDictionary *)dictionarySerialization:(NSDictionary *)dictionary {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    for (NSString *key in [dictionary allKeys]) {
        id value = [dictionary valueForKey:key];
        if ([[value class] isSubclassOfClass:[SModel class]]) {
            [mutableDictionary setObject:[value toDictionary]
                                  forKey:key];
        } else if ([value isKindOfClass:[NSArray class]]){
            [mutableDictionary setObject:[self arraySerialization:value]
                                  forKey:key];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [mutableDictionary setObject:[self dictionarySerialization:value]
                                  forKey:key];
        } else {
            [mutableDictionary setObject:value
                                  forKey:key];
        }
    }
    return [mutableDictionary copy];
}

- (NSArray *)arraySerialization:(NSArray *)array {
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (id value in array) {
        if ([[value class] isSubclassOfClass:[SModel class]]) {
            [mutableArray addObject:[value toDictionary]];
        } else if ([value isKindOfClass:[NSArray class]]){
            [mutableArray addObject:[self arraySerialization:value]];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [mutableArray addObject:[self dictionarySerialization:value]];
        } else {
            [mutableArray addObject:value];
        }
    }
    return [mutableArray copy];
}

// HELPER FUNCTION.

// Get reaction of property on event.
- (NSArray *)getReactionsOfProperty:(NSString *)property
                            onEvent:(SModelEvent)event {
    NSMutableArray *reactions = [NSMutableArray array];
    for (SModelReaction *reaction in [self reactions]) {
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
    for (SModelReaction *reaction in [self reactions]) {
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
    for (SModelAction *action in _actions) {
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
    for (SModelAction *action in _actions) {
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
    for (SModelAction *action in _actions) {
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
    for (SModelAction *action in _actions) {
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
    for (SModelAction *action in _actions) {
        if ([action.keyPath isEqualToString:property]) {
            [actions addObject:action];
        }
    }
    return actions;
}

- (void)registerObserverForKeyPath:(NSString *)keyPath {
    if ([[self getActionsOfProperty:keyPath] count] == 0
        && [[self getReactionsOfProperty:keyPath] count] == 0) {
        [self addObserver:self
               forKeyPath:keyPath
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:SPreadContext];
    }
}

- (void)removeObserverForKeyPath:(NSString *)keyPath {
    if ([[self getActionsOfProperty:keyPath] count] == 0
        && [[self getReactionsOfProperty:keyPath] count] == 0) {
        
        [self removeObserver:self
                  forKeyPath:keyPath
                     context:SPreadContext];
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
        NSLog(@"Duplicated register.");
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
    [_reactions removeObjectsInArray:reactions];
    [self removeObserverForKeyPath:property];
}

- (void)removeReactionsForProperty:(NSString *)property {
    NSArray *reactions = [self getReactionsOfProperty:property];
    if ([reactions count] == 0) return;
    [_reactions removeObjectsInArray:reactions];
    [self removeObserverForKeyPath:property];
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
    NSArray *reactions = [_reactions copy];
    for (SModelReaction *reaction in reactions) {
        [self removeReactionsForProperty:reaction.keyPath];
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
    [_actions removeObjectsInArray:actions];
    [self removeObserverForKeyPath:property];
}

- (void)removeActionsForProperty:(NSString *)property
                          target:(id)target {
    NSArray *actions = [self getActionsOfProperty:property
                                           target:target];
    if ([actions count] == 0) return;
    [_actions removeObjectsInArray:actions];
    [self removeObserverForKeyPath:property];
}

- (void)removeActionsForProperty:(NSString *)property {
    NSArray *actions = [self getActionsOfProperty:property];
    if ([actions count] == 0) return;
    [_actions removeObjectsInArray:actions];
    [self removeObserverForKeyPath:property];
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
    NSArray *actions = [_actions copy];
    for (SModelAction *action in actions) {
        [self removeActionsForProperty:action.keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    id oldValue = change[@"old"];
    id newValue = change[@"new"];
    
    if (context != SPreadContext) {
        return;
    }
    
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
    for (SModelAction *action in actions) {
        if (action.target) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSThread detachNewThreadSelector:action.selector
                                         toTarget:action.target
                                       withObject:self];
            });
        } else {
            [actionsToDelete addObject:action];
        }
    }
    for (SModelAction *action in actionsToDelete) {
        [self removeActionsForProperty:action.keyPath];
    }
}

- (void)fetchInBackground {
    if (self.isFetching) {
        return;
    }
    _fetching = YES;
    __weak SModel *weakSelf = self;
    [SUtils request:[self getSourceUrl]
             method:@"GET"
         parameters:nil
  completionHandler:^(id response, NSError *error) {
      _fetching = NO;
      NSDictionary *data = [SUtils getDataFrom:response
                                   WithKeyPath:[weakSelf getSourceKeyPath]];
      if (data) {
          [weakSelf initData:data];
      }
  }];
}

- (void)fetchInBackground:(void (^)(id, NSError *))completion {
    if (self.isFetching) {
        return;
    }
    _fetching = YES;
    __weak SModel *weakSelf = self;
    [SUtils request:[self getSourceUrl]
             method:@"GET"
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

- (void)setSourceKeyPath:(NSString *)sourceKeyPath {
    _sourceKeyPath = sourceKeyPath;
}

- (void)setSourceUrl:(NSString *)sourceUrl {
    _sourceUrl = sourceUrl;
}

- (NSString *)getSourceKeyPath {
    return _sourceKeyPath;
}

- (NSString *)getSourceUrl {
    return _sourceUrl;
}

- (BOOL)isInitiated {
    return _initiated;
}

- (void)dealloc {
    [self removeAllActions];
    [self removeAllReactions];
}

@end
