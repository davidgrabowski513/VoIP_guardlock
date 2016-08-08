//
//  Constants.h
//  linphone
//
//  Created by developer on 18/05/16.
//
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

//update contact List
+(void)setUpdateValue:(int)value;
+(int)getUpdateValue;

+(void)saveIndexPath:(NSIndexPath *)indexPath;
+(NSIndexPath*)getIndexPath;

+(void)saveContactUsername:(NSString *)username;
+(NSString *)getContactUsername;

+(void)setIsRemove:(bool) isRemove;
+(bool)IsRemove;

//show or hide Setting Icon
+(void)setSettingHide:(BOOL *)isHide;
+(BOOL *)getSeetingHide;

//for reSign(Login)
+(void) setReSignWithValue:(bool)value;
+(bool) getResign;

// web user
+(void) setWebUserWithValue: (bool)value;
+(bool) getWebUser;

//user data
+(void) saveAddress:(NSString *)username withPassword:(NSString *)password;
+(NSString *)getAddress;
+(NSString *)getPassword;
+(void) saveUserId:(NSString *)user_id;
+(NSString *)getUserId;
@end
