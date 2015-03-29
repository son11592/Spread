//
//  SModel.h
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SModel : NSObject

/**
 *  Auto mapping properties object with dictrionary/json.
 *
 *  @param dictionary data to mapping.
 *
 *  @return object mapping.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 *  Register reaction event when property change value.
 *
 *  @param property property key path.
 *  @param react    reaction handler.
 */
- (void)property:(NSString *)property
   reactOnChange:(void(^)(id newValue))react;

/**
 *  Register reaction event for multi properties.
 *
 *  @param properties array of properties key path.
 *  @param react      reaction handler.
 */
- (void)properties:(NSArray *)properties
     reactOnChange:(void(^)(id newValue))react;

/**
 *  Remove reaction handler for property.
 *
 *  @param property property key path.
 */
- (void)removeReactionForProperty:(NSString *)property;

/**
 *  Remove reaction handler for multi properties.
 *
 *  @param properties array of properties key path.
 */
- (void)removeReactionsForProperties:(NSArray *)properties;

/**
 *  Remove all reactions.
 */
- (void)removeAllReactions;

@end
