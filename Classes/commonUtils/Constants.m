//
//  Constants.m
//  linphone
//
//  Created by developer on 18/05/16.
//
//

#import "Constants.h"

@implementation Constants

static int updateValue = 0;
static NSIndexPath *path = nil;
static BOOL *hideSetting = NO;
static bool isWebUser = NO;
static bool reSign = NO;
static NSString *username;//sip number - login user data
static NSString *password;
bool remover = NO;
static NSString *contactUsername;
static NSString *userId;

+(void)setUpdateValue:(int)value{
    updateValue = value;
}
+(int)getUpdateValue{
    return updateValue;
}
+(void)saveIndexPath:(NSIndexPath *)indexPath{
    path = indexPath;
}
+(NSIndexPath*)getIndexPath{
    return path;
}
+(void)setSettingHide:(BOOL *)isHide{
    hideSetting = isHide;
}
+(BOOL *)getSeetingHide{
    return hideSetting;
}
+(void)setReSignWithValue:(bool)value{
    reSign = value;
}
+(bool)getResign{
    return reSign;
}
+(void)saveAddress:(NSString *)name withPassword:(NSString *)pwd{
    username = name;
    password = pwd;
}
+(NSString *)getAddress{
    return username;
}
+(NSString *)getPassword{
    return password;
}
+(void)saveContactUsername:(NSString *)username {
    contactUsername = username;
}
+(NSString *)getContactUsername{
    return contactUsername;
}
+(void)setIsRemove:(bool)isRemove{
    remover = isRemove;
}
+(bool)IsRemove{
    return remover;
}
+(void)saveUserId:(NSString *)user_id {
    userId = user_id;
}
+(NSString *)getUserId {
    return userId;
}
+(void)setWebUserWithValue:(bool)value{
    isWebUser = value;
}
+(bool)getWebUser{
    return isWebUser;
}
@end
