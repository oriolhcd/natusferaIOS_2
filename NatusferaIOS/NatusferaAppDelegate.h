//
//  NatusferaAppDelegate.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h> //añadido por M.Lujano
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@class LoginController;

@interface NatusferaAppDelegate : UIResponder <UIApplicationDelegate> //'comentado por M.Lujano

//@interface NatusferaAppDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate> //añadido M.Lujano

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
