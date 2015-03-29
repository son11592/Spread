
#import "NSObject+SObservers.h"
#import "NSObject+SExecuteOnDealloc.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString const *NSObjectKVOSObserversArrayKey = @"NSObjectKVOSObserversArrayKey";
static NSString const *NSObjectKVOSObserversAllowMethodForwardingKey = @"NSObjectKVOSObserversAllowMethodForwardingKey";
static NSString *NSObjectKVOSObserversAddSelector = @"s_original_addObserver:forKeyPath:options:context:";
static NSString *NSObjectKVOSObserversRemoveSelector = @"s_original_removeObserver:forKeyPath:";
static NSString *NSObjectKVOSObserversRemoveSpecificSelector = @"s_original_removeObserver:forKeyPath:context:";

@interface SObserversKVOObserverInfo : NSObject

@property(nonatomic, copy) NSString *keyPath;
@property(nonatomic, assign) void *context;
@property(nonatomic, assign) void *blockKey;

@end

@implementation SObserversKVOObserverInfo

@end

@implementation NSObject (SFObservers)

+ (void)s_swapSelector:(SEL)aOriginalSelector withSelector:(SEL)aSwappedSelector {
    
    Method originalMethod = class_getInstanceMethod(self, aOriginalSelector);
    Method swappedMethod = class_getInstanceMethod(self, aSwappedSelector);
    
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"s_original_%@", NSStringFromSelector(aOriginalSelector)]);
    class_addMethod([self class], newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    class_replaceMethod([self class], aOriginalSelector, method_getImplementation(swappedMethod), method_getTypeEncoding(swappedMethod));
}

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            [NSObject s_swapSelector:@selector(addObserver:forKeyPath:options:context:) withSelector:@selector(s_addObserver:forKeyPath:options:context:)];
            [NSObject s_swapSelector:@selector(removeObserver:forKeyPath:) withSelector:@selector(s_removeObserver:forKeyPath:)];
            [NSObject s_swapSelector:@selector(removeObserver:forKeyPath:context:) withSelector:@selector(s_removeObserver:forKeyPath:context:)];
        }
    });
}

- (BOOL)allowMethodForwarding {
    
    NSNumber *state = objc_getAssociatedObject(self, (__bridge void *)(NSObjectKVOSObserversAllowMethodForwardingKey));
    return [state boolValue];
}

- (void)setAllowMethodForwarding:(BOOL)allowForwarding {
    
    objc_setAssociatedObject(self, (__bridge void *)(NSObjectKVOSObserversAllowMethodForwardingKey), [NSNumber numberWithBool:allowForwarding], OBJC_ASSOCIATION_RETAIN);
}

- (void)s_addObserver:(id)observer
           forKeyPath:(NSString *)keyPath
              options:(NSKeyValueObservingOptions)options
              context:(void *)context {
    
    // Store info into our observer structure.
    NSMutableDictionary *registeredKeyPaths = (NSMutableDictionary *)objc_getAssociatedObject(observer, (__bridge void *)(NSObjectKVOSObserversArrayKey));
    if (!registeredKeyPaths) {
        registeredKeyPaths = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(observer, (__bridge void *)(NSObjectKVOSObserversArrayKey), registeredKeyPaths, OBJC_ASSOCIATION_RETAIN);
    }
    
    NSMutableArray *observerInfos = [registeredKeyPaths objectForKey:keyPath];
    if (!observerInfos) {
        observerInfos = [NSMutableArray array];
        [registeredKeyPaths setObject:observerInfos forKey:keyPath];
    }
    __block SObserversKVOObserverInfo *observerInfo = nil;
    
    // Don't allow to add many times the same observer.
    [observerInfos enumerateObjectsUsingBlock:^void(id obj, NSUInteger idx, BOOL *stop) {
        SObserversKVOObserverInfo *info = obj;
        if ([info.keyPath isEqualToString:keyPath] && info.context == context) {
            observerInfo = info;
            *stop = YES;
        }
    }];
    
    if (!observerInfo) {
        observerInfo = [[SObserversKVOObserverInfo alloc] init];
        [observerInfos addObject:observerInfo];
    } else {
        // Don't register twice so skip this.
        NSAssert(NO, @"You shouldn't register twice for same keyPath, context");
        return;
    }
    observerInfo.keyPath = keyPath;
    observerInfo.context = context;
    
    // Add auto remove when observer is going to be deallocated.
    __block id weakSelf = self;
    
    void *key = [observer performBlockOnDealloc:^(id obj){
        
        NSLog(@"askjfhaksfhk");
        
        id strongObserver = obj;
        NSInteger numberOfRemovals = 0;
        if ((numberOfRemovals = [weakSelf s_removeObserver:strongObserver
                                                forKeyPath:keyPath context:context
                                        registeredKeyPaths:registeredKeyPaths])) {
            for (NSInteger i = 0; i < numberOfRemovals; ++i) {
                [weakSelf setAllowMethodForwarding:YES];
                ((void(*)(id, SEL, id, NSString *, void *))objc_msgSend)(weakSelf, NSSelectorFromString(NSObjectKVOSObserversRemoveSpecificSelector), strongObserver, keyPath, context);
                [weakSelf setAllowMethodForwarding:NO];
            }
        }
    }];
    observerInfo.blockKey = key;
    ((void(*)(id, SEL, id, NSString *, NSKeyValueObservingOptions,void *))objc_msgSend)(self, NSSelectorFromString(NSObjectKVOSObserversAddSelector), observer, keyPath, options, context);
}

- (void)s_removeObserver:(id)observer forKeyPath:(NSString *)keyPath {
    
    if ([self allowMethodForwarding]) {
        ((void(*)(id, SEL, id,NSString *))objc_msgSend)(self, NSSelectorFromString(NSObjectKVOSObserversRemoveSelector), observer, keyPath);
        return;
    }
    
    NSMutableDictionary *registeredKeyPaths = (NSMutableDictionary *)objc_getAssociatedObject(observer,
                                              (__bridge void *)(NSObjectKVOSObserversArrayKey));
    NSInteger numberOfRemovals = 0;
    if ((numberOfRemovals = [self s_removeObserver:observer
                                        forKeyPath:keyPath
                                           context:nil
                                registeredKeyPaths:registeredKeyPaths])) {
        for (NSInteger i = 0; i < numberOfRemovals; ++i) {
            [self setAllowMethodForwarding:YES];
            ((void(*)(id, SEL, id, NSString *))objc_msgSend)(self, NSSelectorFromString(NSObjectKVOSObserversRemoveSelector), observer, keyPath);
            [self setAllowMethodForwarding:NO];
        }
    }
}

- (void)s_removeObserver:(id)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    if ([self allowMethodForwarding]) {
        ((void(*)(id, SEL, id, NSString *, void *))objc_msgSend)(self, NSSelectorFromString(NSObjectKVOSObserversRemoveSpecificSelector), observer, keyPath, context);
        return;
    }
    
    NSMutableDictionary *registeredKeyPaths = (NSMutableDictionary *)objc_getAssociatedObject(observer,
                                              (__bridge void *)(NSObjectKVOSObserversArrayKey));
    NSInteger numberOfRemovals = 0;
    if ([self allowMethodForwarding] || (numberOfRemovals = [self s_removeObserver:observer forKeyPath:keyPath context:context registeredKeyPaths:registeredKeyPaths])) {
        for (NSInteger i = 0; i < numberOfRemovals; ++i) {
            [self setAllowMethodForwarding:YES];
             ((void(*)(id, SEL, id, NSString *, void *))objc_msgSend)(self, NSSelectorFromString(NSObjectKVOSObserversRemoveSpecificSelector), observer, keyPath, context);
            [self setAllowMethodForwarding:NO];
        }
    }
    
}

- (NSUInteger)s_removeObserver:(id)observer
                    forKeyPath:(NSString *)keyPath
                       context:(void *)context
            registeredKeyPaths:(NSMutableDictionary *)registeredKeyPaths {
    
    __block NSUInteger result = 0;
    if ([keyPath length] <= 0 && context == nil) {

        // Don't need to execute block on dealloc so cleanup.
        [registeredKeyPaths enumerateKeysAndObjectsUsingBlock:^void(id key, id obj, BOOL *stop) {
            NSMutableArray *observerInfos = obj;
            [observerInfos enumerateObjectsUsingBlock:^void(id innerObj, NSUInteger idx, BOOL *innerStop) {
                SObserversKVOObserverInfo *info = innerObj;
                [observer cancelDeallocBlockWithKey:info.blockKey];
            }];
        }];
        [registeredKeyPaths removeAllObjects];
        return 1;
    } else {
        [registeredKeyPaths enumerateKeysAndObjectsUsingBlock:^void(id key, id obj, BOOL *stop) {
            NSMutableArray *observerInfos = obj;
            NSMutableArray *objectsToRemove = [NSMutableArray array];
            [observerInfos enumerateObjectsUsingBlock:^void(id innerObj, NSUInteger idx, BOOL *innerStop) {
                SObserversKVOObserverInfo *info = innerObj;
                
                if ((!keyPath || [keyPath isEqualToString:info.keyPath]) && (context == info.context)) {
                    // Remove this info.
                    [objectsToRemove addObject:innerObj];
                    
                    // Cancel dealloc block.
                    [observer cancelDeallocBlockWithKey:info.blockKey];
                }
            }];
            
            // Remove all collected objects.
            if ([objectsToRemove count] > 0) {
                // Multiple registrations should match unregistrations.
                result  = 1;
                [observerInfos removeObjectsInArray:objectsToRemove];
            }
        }];
    }
    return result;
}
@end
