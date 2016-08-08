
/* AssistantViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "AssistantView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UITextField+DoneButton.h"
#import "UIAssistantTextField.h"

#import <XMLRPCConnection.h>
#import <XMLRPCConnectionManager.h>
#import <XMLRPCResponse.h>
#import <XMLRPCRequest.h>
#import "Constants.h"
#import "CommonUtils.h"

typedef enum _ViewElement {
	ViewElement_Username = 100,
	ViewElement_Password = 101,
	ViewElement_Password2 = 102,
	ViewElement_Email = 103,
	ViewElement_Domain = 104,
	ViewElement_URL = 105,
	ViewElement_DisplayName = 106,
	ViewElement_TextFieldCount = 7,
	ViewElement_Transport = 110,
	ViewElement_Username_Label = 120,
	ViewElement_NextButton = 130,
    ViewElement_Current_Password = 140,
    ViewElement_New_Password = 141,
    ViewElement_Confirm_Password = 142,
    ViewElement_Change_Button = 107
} ViewElement;

@implementation AssistantView

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
	if (self != nil) {
		[[NSBundle mainBundle] loadNibNamed:@"AssistantViewScreens" owner:self options:nil];
		historyViews = [[NSMutableArray alloc] init];
		currentView = nil;
	}
    isChangePwd = NO;
	return self;
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:nil//StatusBarView.class
																 tabBar:nil
															   sideMenu:nil //SideMenuView.class
															 fullscreen:false
														 isLeftFragment:NO
														   fragmentWith:nil];

		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(registrationUpdateEvent:)
											   name:kLinphoneRegistrationUpdate
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(configuringUpdate:)
											   name:kLinphoneConfiguringStateUpdate
											 object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(userPlanSelected:) name:NOTIF_PLAN_SELECT object:nil];
    
    //// remove user
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(expiresDateEvent:)
                                               name:@"IAPPurchaseExpired" object:nil];

	new_config = NULL;
	[self resetTextFields];
    [self changeView:_welcomeView back:FALSE animation:FALSE];
//    [self changeView:_loginView back:FALSE animation:FALSE];
	number_of_configs_before = ms_list_size(linphone_core_get_proxy_config_list(LC));
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)fitContent {
	// always resize content view so that it fits whole available width
	CGRect frame = currentView.frame;
	frame.size.width = _contentView.bounds.size.width;
    
    if (currentView == _welcomeView ||
        currentView == _loginView ||
        currentView == _createAccountView) {
        frame.size.height = _contentView.bounds.size.height - 1;
    }
	currentView.frame = frame;

	[_contentView setContentSize:frame.size];
//	[_contentView contentSizeToFit];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//    [self fitContent];
}

#pragma mark - Utils

- (void)resetLiblinphone {
	if (account_creator) {
		linphone_account_creator_unref(account_creator);
		account_creator = NULL;
	}
	[LinphoneManager.instance resetLinphoneCore];
	account_creator = linphone_account_creator_new(
		LC, [LinphoneManager.instance lpConfigStringForKey:@"xmlrpc_url" inSection:@"assistant" withDefault:@""]
				.UTF8String);
	linphone_account_creator_set_user_data(account_creator, (__bridge void *)(self));
	linphone_account_creator_cbs_set_existence_tested(linphone_account_creator_get_callbacks(account_creator),
													  assistant_existence_tested);
	linphone_account_creator_cbs_set_create_account(linphone_account_creator_get_callbacks(account_creator),
													assistant_create_account);
	linphone_account_creator_cbs_set_validation_tested(linphone_account_creator_get_callbacks(account_creator),
													   assistant_validation_tested);
}
- (void)loadAssistantConfig:(NSString *)rcFilename {
	NSString *fullPath = [@"file://" stringByAppendingString:[LinphoneManager bundleFile:rcFilename]];
	linphone_core_set_provisioning_uri(LC, fullPath.UTF8String);
	[LinphoneManager.instance lpConfigSetInt:1 forKey:@"transient_provisioning" inSection:@"misc"];

	[self resetLiblinphone];
}

- (void)reset {
	[LinphoneManager.instance removeAllAccounts];
	[self resetTextFields];
    
//    [self changeView:_welcomeView back:FALSE animation:FALSE];
    [self changeView:_loginView back:FALSE animation:FALSE];
	_waitView.hidden = TRUE;
    
    if ([Constants getResign]){
        [Constants setReSignWithValue:NO];
        UIAssistantTextField *usernameField = [self findTextField:ViewElement_Username];
        UIAssistantTextField *passwordField = [self findTextField:ViewElement_Password];
        
        [usernameField setText:[Constants getAddress]];
        [passwordField setText:[Constants getPassword]];
    }
}

- (void)clearHistory {
	[historyViews removeAllObjects];
}

+ (NSString *)errorForStatus:(LinphoneAccountCreatorStatus)status {
	BOOL usePhoneNumber = [LinphoneManager.instance lpConfigBoolForKey:@"use_phone_number" inSection:@"assistant"];
	switch (status) {
		case LinphoneAccountCreatorEmailInvalid:
			return NSLocalizedString(@"Invalid email.", nil);
		case LinphoneAccountCreatorUsernameInvalid:
			return usePhoneNumber ? NSLocalizedString(@"Invalid phone number.", nil)
								  : NSLocalizedString(@"Invalid username.", nil);
		case LinphoneAccountCreatorUsernameTooShort:
			return usePhoneNumber ? NSLocalizedString(@"Phone number too short.", nil)
								  : NSLocalizedString(@"Username too short.", nil);
		case LinphoneAccountCreatorUsernameTooLong:
			return usePhoneNumber ? NSLocalizedString(@"Phone number too long.", nil)
								  : NSLocalizedString(@"Username too long.", nil);
		case LinphoneAccountCreatorUsernameInvalidSize:
			return usePhoneNumber ? NSLocalizedString(@"Phone number length invalid.", nil)
								  : NSLocalizedString(@"Username length invalid.", nil);
		case LinphoneAccountCreatorPasswordTooShort:
			return NSLocalizedString(@"Password too short.", nil);
		case LinphoneAccountCreatorPasswordTooLong:
			return NSLocalizedString(@"Password too long.", nil);
		case LinphoneAccountCreatorDomainInvalid:
			return NSLocalizedString(@"Invalid domain.", nil);
		case LinphoneAccountCreatorRouteInvalid:
			return NSLocalizedString(@"Invalid route.", nil);
		case LinphoneAccountCreatorDisplayNameInvalid:
			return NSLocalizedString(@"Invalid display name.", nil);
		case LinphoneAccountCreatorReqFailed:
			return NSLocalizedString(@"Failed to query the server. Please try again later", nil);
		case LinphoneAccountCreatorTransportNotSupported:
			return NSLocalizedString(@"Unsupported transport", nil);
		case LinphoneAccountCreatorAccountCreated:
		case LinphoneAccountCreatorAccountExist:
		case LinphoneAccountCreatorAccountNotCreated:
		case LinphoneAccountCreatorAccountNotExist:
		case LinphoneAccountCreatorAccountNotValidated:
		case LinphoneAccountCreatorAccountValidated:
		case LinphoneAccountCreatorOK:
			break;
	}
	return nil;
}

- (void)configureProxyConfig {
	LinphoneManager *lm = LinphoneManager.instance;

	if (!linphone_core_is_network_reachable(LC)) {
//		UIAlertView *error =
//			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Error", nil)
//									   message:NSLocalizedString(@"There is no network connection available, enable "
//																 @"WIFI or WWAN prior to configure an account",
//																 nil)
//									  delegate:nil
//							 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
//							 otherButtonTitles:nil];
//		[error show];
		_waitView.hidden = YES;
		return;
	}

	// remove previous proxy config, if any
	if (new_config != NULL) {
		const LinphoneAuthInfo *auth = linphone_proxy_config_find_auth_info(new_config);
		linphone_core_remove_proxy_config(LC, new_config);
		if (auth) {
			linphone_core_remove_auth_info(LC, auth);
		}
	}

	// set transport
//    NSString *type = @"TCP";
//    linphone_account_creator_set_transport(account_creator, linphone_transport_parse(type.lowercaseString.UTF8String));
//	UISegmentedControl *transports = (UISegmentedControl *)[self findView:ViewElement_Transport
//																   inView:self.contentView
//																   ofType:UISegmentedControl.class];
//	if (transports) {
//		NSString *type = [transports titleForSegmentAtIndex:[transports selectedSegmentIndex]];
//		linphone_account_creator_set_transport(account_creator,
//											   linphone_transport_parse(type.lowercaseString.UTF8String));
//	}

	new_config = linphone_account_creator_configure(account_creator);

	if (new_config) {
		[lm configurePushTokenForProxyConfig:new_config];
		linphone_core_set_default_proxy_config(LC, new_config);
		// reload address book to prepend proxy config domain to contacts' phone number
		// todo: STOP doing that!
		[[LinphoneManager.instance fastAddressBook] reload];
	}
}

#pragma mark - UI update

- (void)changeView:(UIView *)view back:(BOOL)back animation:(BOOL)animation {

	static BOOL placement_done = NO; // indicates if the button placement has been done in the assistant choice view

    _backButton.hidden = (view == _welcomeView || view == _loginView);

	[self displayUsernameAsPhoneOrUsername];

	if (view == _welcomeView) {
		BOOL show_logo = [LinphoneManager.instance lpConfigBoolForKey:@"show_assistant_logo_in_choice_view_preference"];
		BOOL show_extern = ![LinphoneManager.instance lpConfigBoolForKey:@"hide_assistant_custom_account"];
		BOOL show_new = ![LinphoneManager.instance lpConfigBoolForKey:@"hide_assistant_create_account"];

		if (!placement_done) {
			// visibility
			_welcomeLogoImage.hidden = !show_logo;
			_gotoLoginButton.hidden = !show_extern;
			_gotoCreateAccountButton.hidden = !show_new;

			// placement
			if (show_logo && show_new && !show_extern) {
				// lower both remaining buttons
				[_gotoCreateAccountButton setCenter:[_gotoLinphoneLoginButton center]];
				[_gotoLoginButton setCenter:[_gotoLoginButton center]];

			} else if (!show_logo && !show_new && show_extern) {
				// move up the extern button
				[_gotoLoginButton setCenter:[_gotoCreateAccountButton center]];
			}
			placement_done = YES;
		}
		if (!show_extern && !show_logo) {
			// no option to create or specify a custom account: go to connect view directly
			view = _linphoneLoginView;
		}
	}

	// Animation
	if (animation && ANIMATED) {
		CATransition *trans = [CATransition animation];
		[trans setType:kCATransitionPush];
		[trans setDuration:0.35];
		[trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		if (back) {
			[trans setSubtype:kCATransitionFromLeft];
		} else {
			[trans setSubtype:kCATransitionFromRight];
		}
		[_contentView.layer addAnimation:trans forKey:@"Transition"];
	}

	// Stack current view
	if (currentView != nil) {
		if (!back)
			[historyViews addObject:currentView];
		[currentView removeFromSuperview];
	}

	// Set current view
	currentView = view;
	[_contentView insertSubview:currentView atIndex:0];
	[_contentView setContentOffset:CGPointMake(0, -_contentView.contentInset.top) animated:NO];
	[self fitContent];

	// Resize next button to fix text length
//	UIButton *button = [self findButton:ViewElement_NextButton];
//	CGSize size = [button.titleLabel.text sizeWithFont:button.titleLabel.font];
//	size.width += 60;
//	CGRect frame = button.frame;
//	frame.origin.x += (button.frame.size.width - size.width) / 2;
//	frame.size.width = size.width;
//	[button setFrame:frame];
//
//	[self prepareErrorLabels];
//    if (view == _welcomeView) {
//        [self onGotoLoginClick:nil];
//        [self performSelector:@selector(onGotoLoginClick:) withObject:nil afterDelay:2];
//    }
}

- (void)fillDefaultValues {
//	[self resetTextFields];

	LinphoneProxyConfig *default_conf = linphone_core_create_proxy_config(LC);
	const char *identity = linphone_proxy_config_get_identity(default_conf);
	if (identity) {
		LinphoneAddress *default_addr = linphone_core_interpret_url(LC, identity);
		if (default_addr) {
			const char *domain = linphone_address_get_domain(default_addr);
			const char *username = linphone_address_get_username(default_addr);
			if (domain && strlen(domain) > 0) {
				[self findTextField:ViewElement_Domain].text = [NSString stringWithUTF8String:domain];
			}
			if (username && strlen(username) > 0 && username[0] != '?') {
				[self findTextField:ViewElement_Username].text = [NSString stringWithUTF8String:username];
			}
		}
	}

	[self changeView:_remoteProvisioningLoginView back:FALSE animation:TRUE];

	linphone_proxy_config_destroy(default_conf);
}

- (void)resetTextFields {
	for (UIView *view in @[
			 _welcomeView,
			 _createAccountView,
			 _linphoneLoginView,
			 _loginView,
			 _createAccountActivationView,
			 _remoteProvisioningLoginView
		 ]) {
		[AssistantView cleanTextField:view];
#if DEBUG
		UIAssistantTextField *atf =
			(UIAssistantTextField *)[self findView:ViewElement_Domain inView:view ofType:UIAssistantTextField.class];
		atf.text = SIP_SERVER;
#endif
	}
}

- (void)displayUsernameAsPhoneOrUsername {
	BOOL usePhoneNumber = [LinphoneManager.instance lpConfigBoolForKey:@"use_phone_number"];

	NSString *label = usePhoneNumber ? NSLocalizedString(@"PHONE NUMBER", nil) : NSLocalizedString(@"USERNAME", nil);
	[self findLabel:ViewElement_Username_Label].text = label;

	UITextField *text = [self findTextField:ViewElement_Username];
	if (usePhoneNumber) {
		text.keyboardType = UIKeyboardTypePhonePad;
		[text addDoneButton];
	} else {
		text.keyboardType = UIKeyboardTypeDefault;
	}
}

+ (void)cleanTextField:(UIView *)view {
	if ([view isKindOfClass:UIAssistantTextField.class]) {
		[(UIAssistantTextField *)view setText:@""];
		((UIAssistantTextField *)view).canShowError = NO;
	} else {
		for (UIView *subview in view.subviews) {
			[AssistantView cleanTextField:subview];
		}
	}
}

- (void)shouldEnableNextButton {
	BOOL invalidInputs = NO;
	for (int i = 0; i < ViewElement_TextFieldCount; i++) {
		UIAssistantTextField *field = [self findTextField:100 + i];
		if (field) {
			invalidInputs |= field.isInvalid;
		}
	}
	[self findButton:ViewElement_NextButton].enabled = !invalidInputs;
    [self findButton:ViewElement_Change_Button].enabled = !invalidInputs;
}

- (UIView *)findView:(ViewElement)tag inView:view ofType:(Class)type {
	for (UIView *child in [view subviews]) {
		if (child.tag == tag) {
			return child;
		} else {
			UIView *o = [self findView:tag inView:child ofType:type];
			if (o)
				return o;
		}
	}
	return nil;
}

- (UIAssistantTextField *)findTextField:(ViewElement)tag {
	return (UIAssistantTextField *)[self findView:tag inView:self.contentView ofType:[UIAssistantTextField class]];
}

- (UIButton *)findButton:(ViewElement)tag {
	return (UIButton *)[self findView:tag inView:self.contentView ofType:[UIButton class]];
}

- (UILabel *)findLabel:(ViewElement)tag {
	return (UILabel *)[self findView:tag inView:self.contentView ofType:[UILabel class]];
}

- (void)prepareErrorLabels {
	UIAssistantTextField *createUsername = [self findTextField:ViewElement_Username];
	[createUsername showError:[AssistantView errorForStatus:LinphoneAccountCreatorUsernameInvalid]
						 when:^BOOL(NSString *inputEntry) {
						   LinphoneAccountCreatorStatus s =
							   linphone_account_creator_set_username(account_creator, inputEntry.UTF8String);
						   createUsername.errorLabel.text = [AssistantView errorForStatus:s];
						   return s != LinphoneAccountCreatorOK;
						 }];

	UIAssistantTextField *password = [self findTextField:ViewElement_Password];
	[password showError:[AssistantView errorForStatus:LinphoneAccountCreatorPasswordTooShort]
				   when:^BOOL(NSString *inputEntry) {
					 LinphoneAccountCreatorStatus s =
						 linphone_account_creator_set_password(account_creator, inputEntry.UTF8String);
					 password.errorLabel.text = [AssistantView errorForStatus:s];
					 return s != LinphoneAccountCreatorOK;
				   }];

	UIAssistantTextField *password2 = [self findTextField:ViewElement_Password2];
	[password2 showError:NSLocalizedString(@"Passwords do not match.", nil)
					when:^BOOL(NSString *inputEntry) {
					  return ![inputEntry isEqualToString:[self findTextField:ViewElement_Password].text];
					}];

	UIAssistantTextField *email = [self findTextField:ViewElement_Email];
	[email showError:[AssistantView errorForStatus:LinphoneAccountCreatorEmailInvalid]
				when:^BOOL(NSString *inputEntry) {
				  LinphoneAccountCreatorStatus s =
					  linphone_account_creator_set_email(account_creator, inputEntry.UTF8String);
				  email.errorLabel.text = [AssistantView errorForStatus:s];
				  return s != LinphoneAccountCreatorOK;
				}];

	UIAssistantTextField *domain = [self findTextField:ViewElement_Domain];
	[domain showError:[AssistantView errorForStatus:LinphoneAccountCreatorDomainInvalid]
				 when:^BOOL(NSString *inputEntry) {
				   LinphoneAccountCreatorStatus s =
					   linphone_account_creator_set_domain(account_creator, inputEntry.UTF8String);
				   domain.errorLabel.text = [AssistantView errorForStatus:s];
				   return s != LinphoneAccountCreatorOK;
				 }];

	UIAssistantTextField *url = [self findTextField:ViewElement_URL];
	[url showError:NSLocalizedString(@"Invalid remote provisioning URL", nil)
			  when:^BOOL(NSString *inputEntry) {
				if (inputEntry.length > 0) {
					// missing prefix will result in http:// being used
					if ([inputEntry rangeOfString:@"://"].location == NSNotFound) {
						inputEntry = [NSString stringWithFormat:@"http://%@", inputEntry];
					}
					return (linphone_core_set_provisioning_uri(LC, inputEntry.UTF8String) != 0);
				}
				return TRUE;
			  }];

	UIAssistantTextField *displayName = [self findTextField:ViewElement_DisplayName];
	[displayName showError:[AssistantView errorForStatus:LinphoneAccountCreatorDisplayNameInvalid]
					  when:^BOOL(NSString *inputEntry) {
						LinphoneAccountCreatorStatus s = LinphoneAccountCreatorOK;
						if (inputEntry.length > 0) {
							s = linphone_account_creator_set_display_name(account_creator, inputEntry.UTF8String);
							displayName.errorLabel.text = [AssistantView errorForStatus:s];
						}
						return s != LinphoneAccountCreatorOK;
					  }];

	[self shouldEnableNextButton];
}

#pragma mark - Event Functions

- (void)registrationUpdateEvent:(NSNotification *)notif {
	NSString *message = [notif.userInfo objectForKey:@"message"];
	[self registrationUpdate:[[notif.userInfo objectForKey:@"state"] intValue]
					forProxy:[[notif.userInfo objectForKeyedSubscript:@"cfg"] pointerValue]
					 message:message];
}

- (void)registrationUpdate:(LinphoneRegistrationState)state
				  forProxy:(LinphoneProxyConfig *)proxy
				   message:(NSString *)message {
	// in assistant we only care about ourself
	if (proxy != new_config) {
		return;
	}

	switch (state) {
		case LinphoneRegistrationOk: {
			_waitView.hidden = true;
        
//            [LinphoneManager.instance.iapManager purchaseAccount:[Constants getAddress] withPassword:[Constants getPassword] andEmail:@"" monthly:[[AppConfig getUserPlan] isEqualToString:PARAM_PLAN_MONTHLY]?YES:NO];
//            
			[PhoneMainView.instance popToView:DialerView.compositeViewDescription];
			break;
		}
		case LinphoneRegistrationNone:
		case LinphoneRegistrationCleared: {
			_waitView.hidden = true;
			break;
		}
		case LinphoneRegistrationFailed: {
			_waitView.hidden = true;
			if ([message isEqualToString:@"Forbidden"]) {
				message = NSLocalizedString(@"Incorrect username or password.", nil);
			}
			DTAlertView *alert = [[DTAlertView alloc] initWithTitle:NSLocalizedString(@"Registration failure", nil)
															message:message
														   delegate:nil
												  cancelButtonTitle:@"Cancel"
												  otherButtonTitles:nil];
			[alert addButtonWithTitle:@"Continue"
								block:^(void) {
								  [PhoneMainView.instance popToView:DialerView.compositeViewDescription];
								}];
			[alert show];
			break;
		}
		case LinphoneRegistrationProgress: {
			_waitView.hidden = false;
			break;
		}
		default:
			break;
	}
}

- (void)expiresDateEvent:(NSNotification *)notif {
    [CommonUtils deleteUserAccount:self];
}

- (void)userPlanSelected:(NSNotification *)notif{
    
    _waitView.hidden = NO;
    
    UIAssistantTextField *usernameField = [self findTextField:ViewElement_Username];
    UIAssistantTextField *passwordField = [self findTextField:ViewElement_Password];
    UIAssistantTextField *password2Field = [self findTextField:ViewElement_Password2];
    
    NSString *username = usernameField.text;
    NSString *password = passwordField.text;
    
    NSMutableString *errors = [NSMutableString string];
    if ([username length] == 0) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter username.\n", nil)]];
    } else if ([password length] == 0) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter password. \n", nil)]];
    } else if (![password2Field.text isEqualToString:password]) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Passwords do not match. \n", nil)]];
    }
    
    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length]-1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        _waitView.hidden = YES;
        return;
    }
    
    //init user data
    NSString *post = [[NSString alloc] init];
    
    if ([[AppConfig getUserPlan] isEqualToString:PARAM_PLAN_MONTHLY]){
        post = [NSString stringWithFormat:@"user[username]=%@&user[password]=%@",username,password];
    } else {
        post = [NSString stringWithFormat:@"user[username]=%@&user[password]=%@&user[plan]=%@",username,password,[AppConfig getUserPlan]];
    }
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    
    //init request
    NSString *url = [NSString stringWithFormat:@"%@%@%@%@", HTTP_BASE_URL, HTTP_CREATE_USER, @"?token=", HTTP_API_TOKEN];
    NSURL *nsUrl = [NSURL URLWithString:url];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    // it works well in sandbox test api but not in real admin page, I cant know the reason
    
    //init connect
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        _waitView.hidden = YES;
        
        if (connectionError == nil){
            NSMutableData *responseData = [[NSMutableData alloc] init];
            [responseData appendData:data];
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&connectionError];
            NSString* result = (NSString *)[json valueForKey:@"success"];
            
            if ([[NSString stringWithFormat:@"%@", result] isEqualToString:@"1"]){//sucess
                UIAlertView *sucess = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign Up", nil)
                                                                 message:@"Sucess"
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                                       otherButtonTitles:nil];
                [sucess show];
                
                //get and save user_id
                NSMutableArray *ret = [json objectForKey:@"user_info"];
                NSString *user_id = [ret valueForKey:@"id"];
                [Constants saveUserId:user_id];
                
                //goto login page
                [Constants saveAddress:username withPassword:password];
                [Constants setReSignWithValue:YES];
                [self onBackClick:self];
                [self shouldEnableNextButton];
                [self reset];
                
                //do in-app purchase
//                [LinphoneManager.instance.iapManager purchaseAccount:[Constants getAddress] withPassword:[Constants getPassword] andEmail:@"" monthly:[[AppConfig getUserPlan] isEqualToString:PARAM_PLAN_MONTHLY]?YES:NO];
            
                
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

- (void)configuringUpdate:(NSNotification *)notif {
	LinphoneConfiguringState status = (LinphoneConfiguringState)[[notif.userInfo valueForKey:@"state"] integerValue];

	_waitView.hidden = true;

	switch (status) {
		case LinphoneConfiguringSuccessful:
			// we successfully loaded a remote provisioned config, go to dialer
			if (number_of_configs_before < ms_list_size(linphone_core_get_proxy_config_list(LC))) {
				LOGI(@"A proxy config was set up with the remote provisioning, skip assistant");
				[self onDialerClick:nil];
			}

			if (nextView == nil) {
//				[self fillDefaultValues];
			} else {
				[self changeView:nextView back:false animation:TRUE];
				nextView = nil;
			}
			break;
		case LinphoneConfiguringFailed: {
			NSString *error_message = [notif.userInfo valueForKey:@"message"];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Provisioning Load error", nil)
															message:error_message
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", nil)
												  otherButtonTitles:nil];
			[alert show];
			break;
		}

		case LinphoneConfiguringSkipped:
		default:
			break;
	}
}

#pragma mark - Account creator callbacks

void assistant_existence_tested(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status) {
	AssistantView *thiz = (__bridge AssistantView *)(linphone_account_creator_get_user_data(creator));
	thiz.waitView.hidden = YES;
	if (status == LinphoneAccountCreatorAccountExist) {
		[[thiz findTextField:ViewElement_Username] showError:NSLocalizedString(@"This name is already taken.", nil)];
		[thiz findButton:ViewElement_NextButton].enabled = NO;
	} else if (status == LinphoneAccountCreatorAccountNotExist) {
		linphone_account_creator_create_account(thiz->account_creator);
	}
}

void assistant_create_account(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status) {
	AssistantView *thiz = (__bridge AssistantView *)(linphone_account_creator_get_user_data(creator));
	thiz.waitView.hidden = YES;
	if (status == LinphoneAccountCreatorAccountCreated) {
		[thiz changeView:thiz.createAccountActivationView back:FALSE animation:TRUE];
	} else {
		UIAlertView *errorView = [[UIAlertView alloc]
				initWithTitle:NSLocalizedString(@"Account creation issue", nil)
					  message:NSLocalizedString(@"Your account could not be created, please try again later.", nil)
					 delegate:nil
			cancelButtonTitle:NSLocalizedString(@"Continue", nil)
			otherButtonTitles:nil, nil];
		[errorView show];
	}
}

void assistant_validation_tested(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status) {
	AssistantView *thiz = (__bridge AssistantView *)(linphone_account_creator_get_user_data(creator));
	thiz.waitView.hidden = YES;
	if (status == LinphoneAccountCreatorAccountValidated) {
		[thiz configureProxyConfig];
	} else if (status == LinphoneAccountCreatorAccountNotValidated) {
		DTAlertView *alert = [[DTAlertView alloc]
			initWithTitle:NSLocalizedString(@"Account validation failed", nil)
				  message:
					  NSLocalizedString(
						  @"Your account could not be checked yet. You can skip this validation or try again later.",
						  nil)];
		[alert addCancelButtonWithTitle:NSLocalizedString(@"Back", nil) block:nil];
		[alert addButtonWithTitle:NSLocalizedString(@"Skip verification", nil)
							block:^{
							  [thiz configureProxyConfig];
							  [PhoneMainView.instance popToView:DialerView.compositeViewDescription];
							}];
		[alert show];
	}
}

#pragma mark - UITextFieldDelegate Functions

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isKindOfClass:UIAssistantTextField.class]) {
        UIAssistantTextField *atf = (UIAssistantTextField *)textField;
        [atf textFieldDidEndEditing:atf];
        [self shouldEnableNextButton];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	if (textField.returnKeyType == UIReturnKeyNext) {
		// text fields must be ordored by increasing tag value
		NSInteger tag = textField.tag + 1;
		while (tag < ViewElement_NextButton) {
			UIView *v = [self.view viewWithTag:tag];
			if ([v isKindOfClass:UITextField.class]) {
				[v becomeFirstResponder];
				break;
			}
			tag++;
		}
	} else if (textField.returnKeyType == UIReturnKeyDone) {
        UIButton *nextButton = [self findButton:ViewElement_NextButton];
        if (nextButton) {
            [nextButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
	}
	return YES;
}

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
    BOOL replace = YES;
    
    if ([textField isKindOfClass:UIAssistantTextField.class]) {
        UIAssistantTextField *atf = (UIAssistantTextField *)textField;
        
        // if we are hitting backspace on secure entry, this will clear all text
        if ([string isEqual:@""] && textField.isSecureTextEntry) {
            range = NSMakeRange(0, atf.text.length);
        }
        [atf textField:atf shouldChangeCharactersInRange:range replacementString:string];
        if (atf.tag == ViewElement_Username && currentView == _createAccountView) {
            atf.text = [atf.text stringByReplacingCharactersInRange:range withString:string.lowercaseString];
            replace = NO;
        }
        [self shouldEnableNextButton];
    }
	
	return replace;
}

#pragma mark - Action Functions

- (IBAction)onGotoCreateAccountClick:(id)sender {
	nextView = _createAccountView;
	[self loadAssistantConfig:@"assistant_linphone_create.rc"];
}

- (IBAction)onGotoLinphoneLoginClick:(id)sender {
	nextView = _linphoneLoginView;
	[self loadAssistantConfig:@"assistant_linphone_existing.rc"];
}

- (IBAction)onGotoLoginClick:(id)sender {
	nextView = _loginView;
	[self loadAssistantConfig:@"assistant_external_sip.rc"];
}

- (IBAction)onGotoRemoteProvisioningClick:(id)sender {
	nextView = _remoteProvisioningView;
	[self loadAssistantConfig:@"assistant_remote.rc"];
	[self findTextField:ViewElement_URL].text =
		[LinphoneManager.instance lpConfigStringForKey:@"config-uri" inSection:@"misc"];
}

- (IBAction)onGotoSignUpClick:(id)sender {
//    [self changeView:_remoteProvisioningView back:FALSE animation:TRUE];
    [self changeView:_signUpView back:FALSE animation:TRUE];
}

- (IBAction)onCreateAccountClick:(id)sender {
	_waitView.hidden = NO;
	linphone_account_creator_test_existence(account_creator);
}

- (IBAction)onCreateAccountActivationClick:(id)sender {
	_waitView.hidden = NO;
	linphone_account_creator_test_validation(account_creator);
}

- (IBAction)onLinphoneLoginClick:(id)sender {
	_waitView.hidden = NO;
	[self configureProxyConfig];
}

- (IBAction)onLoginClick:(id)sender {
    UIAssistantTextField *usernameField = [self findTextField:ViewElement_Username];
    UIAssistantTextField *passwordField = [self findTextField:ViewElement_Password];
    
    NSString *username = usernameField.text;
    NSString *password = passwordField.text;
    
    if (![username isEqualToString:[Constants getAddress]]){
        [Constants setWebUserWithValue:YES];
    } else {
        [Constants setWebUserWithValue:NO];
    }
    
    NSMutableString *errors = [NSMutableString string];
    if ([username length] == 0) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter username.\n", nil)]];
    } else if ([password length] == 0) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter password", nil)]];
    }
    
    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
    } else {
        if (!account_creator) {
            [self loadAssistantConfig:@"assistant_external_sip.rc"];
        }
        LinphoneAccountCreatorStatus s = linphone_account_creator_set_username(account_creator, [username UTF8String]);
        s = linphone_account_creator_set_password(account_creator, [password UTF8String]);
        s = linphone_account_creator_set_domain(account_creator, SIP_SERVER.UTF8String);
        s = linphone_account_creator_set_transport(account_creator, linphone_transport_parse(SIP_TRANSPORT_METHOD.lowercaseString.UTF8String));
        _waitView.hidden = NO;
        [self configureProxyConfig];
        
        [Constants saveAddress:username withPassword:password];
        
//        //test
//        [LinphoneManager.instance.iapManager purchaseAccount:[Constants getAddress] withPassword:[Constants getPassword] andEmail:@"" monthly:[[AppConfig getUserPlan] isEqualToString:PARAM_PLAN_MONTHLY]?YES:NO];
    }
}

- (IBAction)onSignUpClick:(id)sender {
       [CommonUtils selectUserPlan:self];
}

- (IBAction)onRemoteProvisioningLoginClick:(id)sender {
	_waitView.hidden = NO;
	[LinphoneManager.instance lpConfigSetInt:1 forKey:@"transient_provisioning" inSection:@"misc"];
	[self configureProxyConfig];
}

- (IBAction)onRemoteProvisioningDownloadClick:(id)sender {
	[_waitView setHidden:false];
	[self resetLiblinphone];
}

- (IBAction)onBackClick:(id)sender {
    if (isChangePwd){
       [PhoneMainView.instance popToView:DialerView.compositeViewDescription];
        isChangePwd = NO;
    } else if ([historyViews count] > 0) {
		UIView *view = [historyViews lastObject];
		[historyViews removeLastObject];
		[self changeView:view back:TRUE animation:TRUE];
	}
}

- (IBAction)onDialerClick:(id)sender {
	[PhoneMainView.instance popToView:DialerView.compositeViewDescription];
}

- (IBAction)onChangeClick:(id)sender {
    _waitView.hidden = NO;
    UIAssistantTextField *password = [self findTextField:ViewElement_Current_Password];
    UIAssistantTextField *newPassword = [self findTextField:ViewElement_New_Password];
    UIAssistantTextField *confirmPassword = [self findTextField:ViewElement_Confirm_Password];
    
    NSString * pwd = password.text;
    NSString *newPwd = newPassword.text;
    NSString *confirmPass = confirmPassword.text;
    
    NSMutableString *errors = [NSMutableString string];
    if ([pwd length] == 0) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter password.\n", nil)]];
    } else if ([newPwd length] == 0) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter new password.\n", nil)]];
    } else if ([confirmPass length] == 0){
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please re-enter new password.\n", nil)]];
    } else if (![pwd isEqualToString:[Constants getPassword]]){
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Password is incorrect.\n", nil)]];
    } else if (![newPwd isEqualToString:confirmPass]){
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"The passwords do not match.\n", nil)]];
    }
    
    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        _waitView.hidden = YES;
        return;
    }
    
    //http
    NSString *post = [NSString stringWithFormat:@"user[current_password]=%@&user[password]=%@&user[password_confirmation]=%@&user[plan]=%@",pwd,newPwd,confirmPass, [AppConfig getUserPlan]];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    
    //init request
    NSString *url = [NSString stringWithFormat:@"%@%@%@%@%@", HTTP_BASE_URL, HTTP_UPDATE_USER, [Constants getUserId], @"?token=", HTTP_API_TOKEN];
    NSURL *nsUrl = [NSURL URLWithString:url];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl];
    [request setHTTPMethod:@"PATCH"];
    [request setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //init connect
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        _waitView.hidden = YES;
        
        if (connectionError == nil){
            NSMutableData *responseData = [[NSMutableData alloc] init];
            [responseData appendData:data];
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&connectionError];
            NSString* result = (NSString *)[json valueForKey:@"success"];
            
            if ([[NSString stringWithFormat:@"%@", result] isEqualToString:@"1"]){//sucess
                UIAlertView *sucess = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Change Password", nil)
                                                                 message:@"Sucess"
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                                       otherButtonTitles:nil];
                [sucess show];
                //goto login page
                [PhoneMainView.instance popToView:DialerView.compositeViewDescription];
                
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

// test in app purchase
- (IBAction)onPurchaseClick:(id)sender {
//    [LinphoneManager.instance.iapManager purchaseAccount:@"test" withPassword:@"12345678" andEmail:@"" monthly:YES];
}

// change password
- (void) gotoChagePassword:(id)sender {
    [self changeView:_changePwdView back:NO animation:YES];
}

- (void) addViewToHistory:(id)view{
    isChangePwd = YES;
}
@end
