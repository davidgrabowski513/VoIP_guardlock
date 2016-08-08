//
//  CommonUtils.m
//  SportsE
//
//  Created by star on 6/22/15.
//  Copyright (c) 2015 star. All rights reserved.
//

#import "CommonUtils.h"
#import "DTAlertView.h"
#import "PhoneMainView.h"
#import "Constants.h"

//static CustomIOS7AlertView *customAlertView;

@implementation CommonUtils

+ (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate tag:(int)tag {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert setTag:tag];
    [alert show];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

//+ (CustomIOS7AlertView *) showCustomAlertView:(UIView *) parentView view:(UIView *) view buttonTitleList:(NSMutableArray *)buttonTitleList completionBlock: (void (^)(int buttonIndex))completionBlock
//{
//    if (customAlertView == nil) {
//        customAlertView = [[CustomIOS7AlertView alloc] init];
//    } else {
//        for (UIView *view in customAlertView.subviews) {
//            [view removeFromSuperview];
//        }
//    }
//    
//    // Add some custom content to the alert view
//    [customAlertView setContainerView:view];
//    
//    // Modify the parameters
//    [customAlertView setButtonTitles:buttonTitleList];
//    
//    // You may use a Block, rather than a delegate.
//    [customAlertView setOnButtonTouchUpInside:^(CustomIOS7AlertView *alertView, int buttonIndex) {
//        NSLog(@"Block: Button at position %d is clicked on alertView %ld.", buttonIndex, (long)[alertView tag]);
//        [alertView close];
//        completionBlock (buttonIndex);
//    }];
//    
//    customAlertView.parentView = parentView;
//    [customAlertView show]; 
//    [customAlertView setUseMotionEffects:true]; 
//    
//    return customAlertView; 
//}

+ (NSArray *)getCountryArray {
    NSString* filePathofState = [[NSBundle mainBundle] pathForResource:@"country-3166alpha3" ofType:@"json"];
    NSData* fileData = [[NSData alloc] initWithContentsOfFile:filePathofState options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableContainers error:nil];
    NSMutableArray *keyArray = [[dic allKeys] mutableCopy];
    
    NSMutableArray *codeArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < keyArray.count; i++) {
        CountryModel *model = [[CountryModel alloc] init];
        model.code = keyArray[i];
        model.name = [dic objectForKey:keyArray[i]];

        [codeArray addObject:model];
    }
    
    return codeArray;
}

+ (NSArray *)getCountryNameArray {
    NSString* filePathofState = [[NSBundle mainBundle] pathForResource:@"country-3166alpha3" ofType:@"json"];
    NSData* fileData = [[NSData alloc] initWithContentsOfFile:filePathofState options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableContainers error:nil];
    NSMutableArray *keyArray = [[dic allKeys] mutableCopy];
    
    NSMutableArray *nameArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < keyArray.count; i++) {
        [nameArray addObject:[dic objectForKey:keyArray[i]]];
    }
    [nameArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
    return nameArray;
}

+ (NSString *)getCountryCodeForName:(NSString *)name {
    NSString* filePathofState = [[NSBundle mainBundle] pathForResource:@"country-3166alpha3" ofType:@"json"];
    NSData* fileData = [[NSData alloc] initWithContentsOfFile:filePathofState options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableContainers error:nil];
    NSMutableArray *keyArray = [[dic allKeys] mutableCopy];
    
    NSString *code = @"";
    
    for (int i = 0; i < keyArray.count; i++) {
        if ([[dic objectForKey:keyArray[i]] isEqualToString:name]) {
            code = keyArray[i];
            break;
        }
    }
    
    return code;
}

+ (NSArray *)getCurrencyCodeArray {
    NSString* filePathofState = [[NSBundle mainBundle] pathForResource:@"currency-ISO4217" ofType:@"json"];
    NSData* fileData = [[NSData alloc] initWithContentsOfFile:filePathofState options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableContainers error:nil];
    NSMutableArray *keyArray = [[dic allKeys] mutableCopy];
    [keyArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return keyArray;
    /*
    NSMutableArray *codeArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < keyArray.count; i++) {
        NSDictionary *content = [dic objectForKey:keyArray[i]];
        CurrencyModel *model = [[CurrencyModel alloc] init];
        model.codeString = keyArray[i];
        model.codeNumber = [content objectForKey:@"code"];
        model.counrty = [content objectForKey:@"country"];
        
        [codeArray addObject:model];
    }
    
    return codeArray;
     */
}

+ (void) selectUserPlan:(id)delegate{
    UIAlertController *plan = [UIAlertController alertControllerWithTitle:nil message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:@"Please select your plan"];
    [hogan addAttribute:NSFontAttributeName
                  value:[UIFont systemFontOfSize:40.0]
                  range:NSMakeRange(0, 0)];
    [plan setValue:hogan forKey:@"attributedTitle"];
    
    UIAlertAction *monthly = [UIAlertAction actionWithTitle:@"Monthly($7)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        
        DTAlertView *alert = [[DTAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Monthly subscription", nil)
                              message:
                              NSLocalizedString(@"You should pay monthly. \n OK?",
                                                nil)];
        [alert addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)
                            block:^{
                                [AppConfig setUserPlan:PARAM_PLAN_MONTHLY];
                                [NSNotificationCenter.defaultCenter postNotificationName:NOTIF_PLAN_SELECT object:delegate];
                            }];
        [alert show];
    }];
    UIAlertAction *yearly = [UIAlertAction actionWithTitle:@"Yearly($39)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        DTAlertView *alert = [[DTAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Yearly subscription", nil)
                              message:
                              NSLocalizedString(@"You should pay yearly. \n OK?",
                                                nil)];
        [alert addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)
                            block:^{
                                [AppConfig setUserPlan:PARAM_PLAN_YEARLY];
                                [NSNotificationCenter.defaultCenter postNotificationName:NOTIF_PLAN_SELECT object:delegate];
                            }];
        [alert show];
    }];
    
    [plan addAction:monthly];
    [plan addAction:yearly];
    [delegate presentViewController:plan animated:YES completion:nil];
}

+ (void)sendRequestUrl:(NSURL *)url withMethod:(NSString *)method andParams:(NSDictionary *)data {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    if ([method isEqualToString:@"GET"]){
        
    } else if ([method isEqualToString:@"POST"]){
        [request setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
        NSMutableString *postData = [NSMutableString string];
        for (int i = 0;i < data.count;i++){
            NSArray *allKeys = [data allKeys];
            [postData appendString:[NSString stringWithFormat:@"%@=%@&", allKeys[i], [data valueForKey:allKeys[i]]]];
        }
        NSString *post = (NSString *)[postData substringWithRange:NSMakeRange(0, postData.length-1)];
        
        [request setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

+ (void) deleteUserAccount:(id)delegate{
    //http
    if ([Constants getWebUser]){
        return;
    }
    
    //init request
    NSString *url = [NSString stringWithFormat:@"%@%@%@%@%@", HTTP_BASE_URL, HTTP_UPDATE_USER, [Constants getUserId], @"?token=", HTTP_API_TOKEN];
    NSURL *nsUrl = [NSURL URLWithString:url];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl];
    [request setHTTPMethod:@"DELETE"];
    [request setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    
    //init connect
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        if (connectionError == nil){
            NSMutableData *responseData = [[NSMutableData alloc] init];
            [responseData appendData:data];
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&connectionError];
            NSString* result = (NSString *)[json valueForKey:@"success"];
            
            if ([[NSString stringWithFormat:@"%@", result] isEqualToString:@"1"]){//sucess
                UIAlertView *sucess = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Payment Failed", nil)
                                                                 message:@"Please verify your Apple ID payment information and try again."
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                                       otherButtonTitles:nil];
                [sucess show];
                //goto login Page
                AssistantView *view = VIEW(AssistantView);
                [PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
                [view reset];
                
            } else {//failure
                NSMutableArray *err = [json objectForKey:@"error_messages"];
                NSMutableString *message = [NSMutableString string];
                for (int index=0;index<[err count]-1;index++){
                    [message appendString:[NSString stringWithFormat:@"%@ \n", (NSString*)[err objectAtIndex:index]]];
                }
                [message appendString:[NSString stringWithFormat:@"%@", (NSString*)[err objectAtIndex:[err count]-1]]];
                
                if([message length]) {
                    UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                                        message:[message substringWithRange:NSMakeRange(0, [message length])]
                                                                       delegate:nil
                                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                              otherButtonTitles:nil,nil];
                    [errorView show];
                    return;
                }
            }
        } else {
            UIAlertView *error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Error", nil)
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                                  otherButtonTitles:nil];
            [error show];
        }
    }];
}

@end
