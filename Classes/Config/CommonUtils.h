//
//  CommonUtils.h
//  SportsE
//
//  Created by star on 6/22/15.
//  Copyright (c) 2015 star. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "CountryModel.h"
#import "CurrencyModel.h"

@interface CommonUtils : NSObject

+ (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate tag:(int)tag;

//+ (CustomIOS7AlertView *) showCustomAlertView:(UIView *) parentView view:(UIView *) view buttonTitleList:(NSMutableArray *)buttonTitleList completionBlock: (void (^)(int buttonIndex))completionBlock;

+ (UIImage *)imageWithColor:(UIColor *)color;

+ (NSArray *)getCountryArray;
+ (NSArray *)getCountryNameArray;
+ (NSString *)getCountryCodeForName:(NSString *)name;

+ (NSArray *)getCurrencyCodeArray;

+ (void) selectUserPlan:(id)delegate;

+ (void) sendRequestUrl:(NSURL *)url withMethod:(NSString *)method andParams:(NSDictionary *) data;

+ (void) deleteUserAccount:(id)delegate;
@end
