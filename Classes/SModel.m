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

@implementation SModel {
    
    NSMutableArray *_reactions;
}

- (NSMutableArray *)reactions {
    
    @synchronized(self) {
        if (!_reactions) {
            _reactions = [NSMutableArray array];
        }
    }
    return _reactions;
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

- (NSArray *)getActions:(NSString *)property {
    
    NSMutableArray *reactions = [NSMutableArray array];
    for (SModelReaction *reaction in [self reactions]) {
        if ([reaction.keyPath isEqualToString:property]) {
            [reactions addObject:reaction];
        }
    }
    return reactions;
}

- (void)property:(NSString *)property
   reactOnChange:(void(^)(id newValue))react {
    
    [self addObserver:self
           forKeyPath:property
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
    SModelReaction *reaction = [[SModelReaction alloc] init];
    reaction.keyPath = property;
    reaction.react = react;
    [[self reactions] addObject:reaction];
}

- (void)properties:(NSArray *)properties
     reactOnChange:(void (^)(id))react {
    
    for (NSString *property in properties) {
        [self property:property
         reactOnChange:react];
    }
}

- (void)removeReactionForProperty:(NSString *)property {
    
    NSArray *reactions = [self getActions:property];
    for (SModelReaction *reaction in reactions) {
        [self removeObserver:self
                  forKeyPath:reaction.keyPath];
    }
    [[self reactions] removeObjectsInArray:reactions];
}

- (void)removeReactionsForProperties:(NSArray *)properties {
    
    for (NSString *property in properties) {
        [self removeReactionForProperty:property];
    }
}

- (void)removeAllReactions {
    
    for (SModelReaction *reaction in [self reactions]) {
        [self removeObserver:self
                  forKeyPath:reaction.keyPath];
    }
    [[self reactions] removeAllObjects];
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
}

- (void)dealloc {
    
#ifdef DEBUG
    NSLog(@"Release.");
#endif
    for (SModelReaction *reaction in [self reactions]) {
        [self removeObserver:self forKeyPath:reaction.keyPath];
    }
}

@end
