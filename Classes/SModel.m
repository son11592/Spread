//
//  SModel.m
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SModel.h"

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
@property (nonatomic, copy) void (^react)(id);

@end

@implementation SModelReaction

@end

@interface SModelAction : NSObject

@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL selector;

- (BOOL)compareWith:(SModelAction *)action;
- (BOOL)compareWithTarget:(id)target
                 selector:(SEL)selector
                 property:(NSString *)property;
@end

@implementation SModelAction

- (BOOL)compareWith:(SModelAction *)action {
    
    return [self compareWithTarget:action.target
                          selector:action.selector
                          property:action.keyPath];
}

- (BOOL)compareWithTarget:(id)target
                 selector:(SEL)selector
                 property:(NSString *)property {
    if ([self.target isEqual:target]
        && self.selector == selector
        && [self.keyPath isEqualToString:property]) {
        return YES;
    }
    return NO;
}

@end

@implementation SModel {
    
    // Store callback reaction.
    NSMutableArray *_reactions;
    
    // Store action with target.
    NSMutableArray *_actions;
}

- (NSMutableArray *)reactions {
    
    @synchronized(self) {
        if (!_reactions) {
            _reactions = [NSMutableArray array];
        }
    }
    return _reactions;
}

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
    
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        return self;
    }
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
            
            id value = [dictionary valueForKey:([propertyName characterAtIndex:0] == '_' ?
                                                [propertyName substringFromIndex:1] : propertyName)];
            
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
    return self;
}

- (NSArray *)getReactions:(NSString *)property {
    
    NSMutableArray *reactions = [NSMutableArray array];
    for (SModelReaction *reaction in [self reactions]) {
        if ([reaction.keyPath isEqualToString:property]) {
            [reactions addObject:reaction];
        }
    }
    return reactions;
}

- (NSArray *)getActions:(NSString *)property {
    
    NSMutableArray *actions = [NSMutableArray array];
    for (SModelAction *action in _actions) {
        if ([action.keyPath isEqualToString:property]) {
            [actions addObject:action];
        }
    }
    return actions;
}

- (void)property:(NSString *)property
onChangeReaction:(void(^)(id newValue))react {
    
    if ([[self getReactions:property] count] > 0) {
        
        NSLog(@"This time, we do not allow  multiple reaction register.");
        return;
    }
    
    // When keypath is already register, reuse it.
    if ([[self getActions:property] count] == 0) {
        [self addObserver:self
               forKeyPath:property
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    }
    
    SModelReaction *reaction = [[SModelReaction alloc] init];
    reaction.keyPath = property;
    reaction.react = react;
    [[self reactions] addObject:reaction];
}

- (void)property:(NSString *)property
onChangeReactionTarget:(id)target
        selector:(SEL)action {
    
    if ([[self getActions:property] count] > 0) {
        
        NSLog(@"This time, we do not allow  multiple action register.");
        return;
    }
    
    // When keypath is already register, reuse it.
    if ([[self getReactions:property] count] == 0) {
        [self addObserver:self
               forKeyPath:property
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    }
    
    SModelAction *modelAction = [[SModelAction alloc] init];
    modelAction.keyPath = property;
    modelAction.target = target;
    modelAction.selector = action;
    [[self actions] addObject:modelAction];
}

- (void)properties:(NSArray *)properties
  onChangeReaction:(void (^)(id))react {
    
    for (NSString *property in properties) {
        [self property:property
      onChangeReaction:react];
    }
}

- (void)properties:(NSArray *)properties
onChangeReactionTarget:(id)target
          selector:(SEL)action {
    for (NSString *property in properties) {
        [self property:property
onChangeReactionTarget:target
              selector:action];
    }
}

- (void)removeReactionObserverForKeyPath:(NSString *)keyPath {
    
    // Remove when property have no target lister.
    if ([[self getActions:keyPath] count] == 0) {
        [self removeObserver:self
                  forKeyPath:keyPath];
    }
}

- (void)removeActionObserverForKeyPath:(NSString *)keyPath {
    
    // Remove when property have no target lister.
    if ([[self getReactions:keyPath] count] == 0) {
        [self removeObserver:self
                  forKeyPath:keyPath];
    }
}

- (void)removeReactionForProperty:(NSString *)property {
    
    NSArray *reactions = [self getReactions:property];
    for (SModelReaction *reaction in reactions) {
        [self removeReactionObserverForKeyPath:reaction.keyPath];
    }
    [[self reactions] removeObjectsInArray:reactions];
}

- (void)removeActionForProperty:(NSString *)property {
    
    NSArray *actions = [self getActions:property];
    for ( SModelAction *action in actions) {
        [self removeActionObserverForKeyPath:action.keyPath];
    }
    [[self actions] removeObjectsInArray:actions];
}

- (void)removeReactionsForProperties:(NSArray *)properties {
    
    for (NSString *property in properties) {
        [self removeReactionForProperty:property];
    }
}

- (void)removeActionsForProperties:(NSArray *)properties {
    
    for (NSString *property in properties) {
        [self removeActionForProperty:property];
    }
}

- (void)removeAllReactions {
    
    for (SModelReaction *reaction in [self reactions]) {
        [self removeReactionObserverForKeyPath:reaction.keyPath];
    }
    [[self reactions] removeAllObjects];
}

- (void)removeAllActions {
    
    for (SModelAction *action in [self actions]) {
        [self removeActionObserverForKeyPath:action.keyPath];
    }
    [[self actions] removeAllObjects];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    for (SModelReaction *reaction in [self reactions]) {
        if ([reaction.keyPath isEqualToString:keyPath]) {
            reaction.react(change[@"new"]);
        }
    }
    
    // Automatic delete action event when target become nil.
    NSMutableArray *dataToDelete = [NSMutableArray array];
    for (SModelAction *action in [self actions]) {
        if (action.target) {
            if ([action.keyPath isEqualToString:keyPath]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSThread detachNewThreadSelector:action.selector
                                             toTarget:action.target
                                           withObject:self];
                });
            }
        } else {
            [dataToDelete addObject:action];
        }
    }
    [[self actions] removeObjectsInArray:dataToDelete];
    for (SModelAction *action in dataToDelete) {
        [self removeActionForProperty:action.keyPath];
    }
}

- (void)dealloc {
    
    [self removeAllReactions];
    [self removeAllActions];
#ifdef DEBUG
    NSLog(@"[%@] - Release.", [self class]);
#endif
}

@end
