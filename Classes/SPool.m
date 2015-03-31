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
@property (nonatomic, copy) void (^react)(id);

@end

@implementation SPoolReaction

@end

@implementation SPool {
  
  NSMutableArray *_reactions;
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
    _data = [NSMutableArray array];
}

- (NSMutableArray *)reactions {
  
  @synchronized(self) {
    if (!_reactions) {
      _reactions = [NSMutableArray array];
    }
  }
  return _reactions;
}

- (id)addObject:(NSDictionary *)object {
    
    id model = [[self.modelClass alloc] initWithDictionary:object];
    [self.data addObject:model];
    [self triggerReactions];
    return model;
}

- (NSArray *)addObjects:(NSArray *)objects {
 
    NSMutableArray *dataToAdd = [NSMutableArray array];
    for (NSDictionary *object in objects) {
        id model = [[self.modelClass alloc] initWithDictionary:object];
        [dataToAdd addObject:model];
    }
    [self.data addObjectsFromArray:dataToAdd];
    [self triggerReactions];
    return dataToAdd;
}

- (NSArray *)allObjects {
    
    return [self data];
}

- (void)removeObject:(id)object {
    
    [self.data removeObject:object];
    [self triggerReactions];
}

- (void)removeObjects:(NSArray *)objects {
    
    [self.data removeObjectsInArray:objects];
    [self triggerReactions];
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

- (void)reactOnChange:(SPoolEvent)event
                react:(void(^)(id newValue))react {
  
    SPoolReaction *reaction = [[SPoolReaction alloc] init];
    reaction.event = event;
    reaction.react = react;
    [[self reactions] addObject:reaction];
}

- (void)triggerReactions {
  
  for (SPoolReaction *reaction in [self reactions]) {
    reaction.react(self.data);
  }
}

- (void)removeObjectMatch:(BOOL (^)(id))filter {
    
    NSArray *objectToRemove = [self filter:filter];
    [self.data removeObjectsInArray:objectToRemove];
}

@end
