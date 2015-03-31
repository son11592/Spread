//
//  Spread.m
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "Spread.h"

@interface Action: NSObject

@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) NSString *poolIdentifier;
@property (nonatomic, copy) void (^action)(id, SPool *);

@end

@implementation Action

@end

@interface Spread()

@property (nonatomic, strong) NSMutableArray *pools;
@property (nonatomic, strong) NSMutableArray *poolActions;

@end

@implementation Spread

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
    
    _pools = [NSMutableArray array];
    _poolActions = [NSMutableArray array];
}

+ (SPool *)getPool:(NSString *)identifier {
    
    for (SPool *pool in [[self sharedInstance] pools]) {
        if ([pool.identifier isEqualToString:identifier]) {
            return pool;
        }
    }
    return nil;
}

+ (void)registerClass:(Class)modelClass
    forPoolIdentifier:(NSString *)identifier {
    
    SPool *pool = [self getPool:identifier];
    
    @synchronized(self) {
        if (!pool) {
            pool = [[SPool alloc] init];
            pool.identifier = identifier;
            pool.modelClass = modelClass;
            [[[self sharedInstance] pools] addObject:pool];
        } else {
            NSAssert([modelClass isSubclassOfClass:[SModel class]],
                     @"Model register must be SModel or subclass of SModel.");
            NSAssert([pool allObjects].count == 0 || pool.modelClass == modelClass,
                     @"Pool contains model and has been registered with another model class.");
        }
    }
}

+ (NSInteger)countIndentifer:(NSString *)identifier inArray:(NSArray *)array {
    
    NSInteger count = 0;
    for (NSString *string in array) {
        if ([identifier isEqualToString:string]) {
            count++;
        }
    }
    return count;
}

+ (void)registerEvent:(NSString *)event
      poolIdentifiers:(NSArray *)poolIdentifiers
               action:(void (^)(id, SPool *))action {
    
    for (NSString *poolIdentifier in poolIdentifiers) {
#ifdef DEBUG
        if ([self countIndentifer:poolIdentifier inArray:poolIdentifiers] > 1) {
            NSLog(@"[WARNING]: Duplicated pool identifier.");
        }
#endif
        Action *poolAction = [[Action alloc] init];
        poolAction.event = event;
        poolAction.poolIdentifier = poolIdentifier;
        poolAction.action = action;
        [[[self sharedInstance] poolActions] addObject:poolAction];
    }
}

+ (void)removeEvent:(NSString *)event
    poolIdentifiers:(NSArray *)poolIdentifiers {
    
    NSMutableArray *actionsToDelete = [NSMutableArray array];
    for (Action *action in [[self sharedInstance] poolActions]) {
        if ([action.event isEqualToString:event]
            && [self countIndentifer:action.poolIdentifier inArray:poolIdentifiers] > 0) {
            [actionsToDelete addObject:action];
        }
    }
    [[[self sharedInstance] poolActions] removeObjectsInArray:actionsToDelete];
}

+ (void)removeEvent:(NSString *)event {
    
    NSMutableArray *actionsToDelete = [NSMutableArray array];
    for (Action *action in [[self sharedInstance] poolActions]) {
        if ([action.event isEqualToString:event]) {
            [actionsToDelete addObject:action];
        }
    }
    [[[self sharedInstance] poolActions] removeObjectsInArray:actionsToDelete];
}

+ (void)removeAllEvent {
    
    [[[self sharedInstance] poolActions] removeAllObjects];
}

+ (SModel *)addObject:(NSDictionary *)object
               toPool:(NSString *)identifier {
    
    SPool *pool = [self getPool:identifier];
    return [pool addObject:object];
}

+ (NSArray *)addObjects:(NSArray *)objects
                 toPool:(NSString *)identifier {
    
    SPool *pool = [self getPool:identifier];
    return [pool addObjects:objects];
}

+ (void)removeObject:(id)object
            fromPool:(NSString *)identifier {
    
    SPool *pool = [self getPool:identifier];
    if (pool) {
        [pool removeObject:object];
    }
}

+ (void)removeObjects:(NSArray *)objects
             fromPool:(NSString *)identifier {
    
    SPool *pool = [self getPool:identifier];
    [pool removeObjects:objects];
}

+ (void)performEvent:(NSString *)event
               value:(NSDictionary *)value {
    
    for (Action *poolAction in [[self sharedInstance] poolActions]) {
        if ([poolAction.event isEqualToString:event]) {
            SPool *pool = [self getPool:poolAction.poolIdentifier];
            poolAction.action(value, pool);
        }
    }
}

@end
