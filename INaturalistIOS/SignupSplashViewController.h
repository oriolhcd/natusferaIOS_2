//
//  SignupSplashViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/14/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>

@class SplitTextButton;
@class GIDSignInButton;

//@interface SignupSplashViewController : UIViewController // esta línea de código es la antigua M.Lujano

@interface SignupSplashViewController : UIViewController <GIDSignInDelegate>
@property NSString *reason;
@property BOOL skippable;
@property BOOL cancellable;
@property BOOL animateIn;

@property (nonatomic, copy) void(^skipAction)();


// expose UI elements for transition animator
@property UILabel *logoLabel;
@property UILabel *reasonLabel;
@property SplitTextButton *loginFaceButton;
//@property SplitTextButton *loginGButton;
//start loginviewcontroller_vars // las siguientes lineas han sido añadidas por M.Lujano
@property (weak, nonatomic) IBOutlet GIDSignInButton *loginGButton;
@property (weak, nonatomic) IBOutlet UIButton * signOutButton;
@property (weak, nonatomic) IBOutlet UIButton * disconnectButton;
@property (weak, nonatomic) IBOutlet UILabel *statusText;
//end loginviewcontroller_vars
@property SplitTextButton *signupEmailButton;
@property UIButton *signinEmailButton;
@property UIButton *skipButton;
@property UIImageView *backgroundImageView;
@property UIView *blurView;

@end







