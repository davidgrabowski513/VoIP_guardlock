//
//  AppConfig.m
//  linphone
//
//  Created by star on 11/15/15.
//
//

#import "AppConfig.h"
//#import "WebApi.h"

@implementation AppConfig

+ (void)saveStringForKey:(NSString *)key value:(NSString *)value {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:value forKey:key];
    [userDefault synchronize];
}

+ (NSString *)getStringForKey:(NSString *)key {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *value = [userDefault stringForKey:key];
    if (value == nil) {
        value = @"";
    }
    return value;
}

+ (void)updateCredit {
//    NSString *accountNumber = [AppConfig getStringForKey:SIP_USER_NAME];
//    
//    if (accountNumber && accountNumber.length > 0) {
//        NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys: accountNumber, @"accountNumber", nil];
//        [WebApi getAccountBalance:dic usingCallback:^(id result, BOOL error) {
//            if (!error) {
//                NSDictionary *resultDic = (NSDictionary *)result;
//                int errorCode  = [[resultDic objectForKey:@"errorCode"] intValue];
//                if ( errorCode == 0) {
//                    NSString *credit = [resultDic objectForKey:@"credit"];
//                    [AppConfig saveStringForKey:SIP_CREDIT value:credit];
//                    
//                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_SIP_CREDIT_CHANGED object:nil];
//                } else {
//                    NSString *errMsg = [WebApi getErrorMessage:errorCode];
//                }
//            }
//        }];
//    }
}

+(void) setUserPlan:(NSString *)userPlan {
    [self saveStringForKey:PARAM_PLAN_KEY value:userPlan];
}

+(NSString *)getUserPlan{
    NSString *temp = [self getStringForKey:PARAM_PLAN_KEY];
    if (temp == NULL || [temp isEqualToString:@""]){
        temp = PARAM_PLAN_MONTHLY;
    }
    return temp;
}

@end
