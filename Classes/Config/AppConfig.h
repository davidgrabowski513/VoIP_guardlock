//
//  AppConfig.h
//  linphone
//
//  Created by star on 11/15/15.
//
//

#import <Foundation/Foundation.h>

#define APP_NAME                @"GuardLock"

#define SIP_SERVER              @"45.55.88.65"
#define SIP_TRANSPORT_METHOD    @"TCP"
#define SIP_USER_NAME           @"sip_username"
#define SIP_PASSWORD            @"sip_password"
#define SIP_CREDIT              @"sip_credit"

#define PARAM_USERNAME          @"USERNAME"
#define PARAM_FIRSTNAME         @"FIRSTNAME"
#define PARAM_LASTNAME          @"LASTNAME"
#define PARAM_EMAIL             @"EMAIL"
#define PARAM_PASSWORD          @"PASSWORD"
#define PARAM_COUNTRY_CODE      @"COUNTRY_CODE"
#define PARAM_CURRENCTY_CODE    @"CURRENCTY_CODE"
#define PARAM_RESELLERID        @"RESELLERID"
#define PARAM_CREDIT_AMOUNT     @"creditAmount"
#define PARAM_APPLE_RECEIPT     @"appleReceipt"

#define IAP_SHARED_SECRET_KEY   @"d2bc39ebee694c42952f62cfd424fd62"
#define IAP_IS_PRODUCTION_MODE  YES

#define NOTIF_SIP_CREDIT_CHANGED    @"NotificationSipCreditChanged"

//add new params for networking

#define PARAM_IS_PURCASED       @"isPurchased"

#define HTTP_API_TOKEN          @"b4f83106fbbd8565326b29f9fc5bf0de"             //product environment
#define HTTP_BASE_URL           @"https://admin.guardlock.co.il"                //product environment

//#define HTTP_API_TOKEN          @"9e87585c4c8537f58977cc41da53dbfe"           //sandbox environment
//#define HTTP_BASE_URL           @"http://sandbox.guardlock.co.il"              //sandbox environment

#define HTTP_CREATE_USER        @"/api/v1/users"
#define HTTP_UPDATE_USER        @"/api/v1/users/"

//plans - monthly or yearly
#define PARAM_PLAN_KEY          @"plan"
#define PARAM_PLAN_MONTHLY      @"monthly"
#define PARAM_PLAN_YEARLY       @"yearly"

#define NOTIF_PLAN_SELECT       @"notif_plan_selected"

@interface AppConfig : NSObject

+ (void)saveStringForKey:(NSString *)key value:(NSString *)value;
+ (NSString *)getStringForKey:(NSString *)key;

+ (void)updateCredit;

+ (void)setUserPlan:(NSString *)userPlan;
+ (NSString *)getUserPlan;

@end