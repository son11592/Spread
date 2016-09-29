//
//  SRemoteTaskManager.h
//  Spread
//
//  Created by Huy Pham on 4/15/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import "SRemoteTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRemoteTaskManager : NSObject

/**
 *  Add remote task to queue.
 *
 *  @param task Task obejct.
 */
+ (void)addTask:(SRemoteTask *)task;

@end

NS_ASSUME_NONNULL_END
