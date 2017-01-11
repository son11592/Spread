//
//  Milk.h
//  Spread
//
//  Created by Huy Pham on 8/23/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Mapper.h"

@interface Milk : Mapper

@property (nonatomic, copy) NSString *__id;
@property (nonatomic) NSInteger number1;
@property (nonatomic) NSInteger number2;
@property (nonatomic) NSUInteger number3;

@property (nonatomic) BOOL status1;
@property (nonatomic) bool status2;
@property (nonatomic) Boolean status3;

@property (nonatomic) CGFloat cost;
@property (nonatomic) CGSize size;
@property (nonatomic) CGRect rect;
@property (nonatomic) CGPoint point;

@end
