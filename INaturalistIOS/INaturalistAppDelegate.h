//
//  INaturalistAppDelegate.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <GoogleSignIn/GoogleSignIn.h> //añadido por M.Lujano



@class LoginController;

@interface INaturalistAppDelegate : UIResponder <UIApplicationDelegate> //'comentado por M.Lujano

//@interface INaturalistAppDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate> //añadido M.Lujano

@property (strong, nonatomic) UIWindow *window; //corresponde a la ventana de inicio de la aplicación M.Lujano:9-06-2016
@property (strong, nonatomic) RKObjectManager *photoObjectManager;
@property (strong, nonatomic) LoginController *loginController;

- (BOOL)loggedIn;
- (void)showMainUI;
- (void)showInitialSignupUI;

- (void)reconfigureForNewBaseUrl;
- (void)rebuildCoreData;

@end



extern NSString *kInatCoreDataRebuiltNotification;