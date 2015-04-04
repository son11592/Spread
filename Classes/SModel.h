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
onChangeReaction:(void(^)(id newValue))react;

/**
 *  Register action event when property change value.
 *
 *  @param property property key path.
 *  @param target   object for trigger event.
 *  @param action   a selector.
 */
- (void)property:(NSString *)property
onChangeReactionTarget:(id)target
        selector:(SEL)action;

/**
 *  Register reaction event for multi properties.
 *
 *  @param properties array of properties key path.
 *  @param react      reaction handler.
 */
- (void)properties:(NSArray *)properties
  onChangeReaction:(void(^)(id newValue))react;

/**
 *  Register action event when properties change value.
 *
 *  @param properties array of property key path.
 *  @param target     object for trigger event.
 *  @param action     a selector.
 */
- (void)properties:(NSArray *)properties
onChangeReactionTarget:(id)target
          selector:(SEL)action;

/**
 *  Remove reaction handler for property.
 *
 *  @param property property key path.
 */
- (void)removeReactionForProperty:(NSString *)property;

/**
 *  Remove action target for property.
 *
 *  @param property property key path.
 */
- (void)removeActionForProperty:(NSString *)property;

/**
 *  Remove reaction handler for array of property.
 *
 *  @param properties array of property key path.
 */
- (void)removeReactionsForProperties:(NSArray *)properties;

/**
 *  Remove action target for array of property.
 *
 *  @param properties array of property key path.
 */
- (void)removeActionsForProperties:(NSArray *)properties;

/**
 *  Remove all reactions.
 */
- (void)removeAllReactions;

@end
