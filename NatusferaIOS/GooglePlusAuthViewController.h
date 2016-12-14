//
//  GooglePlusAuthViewController.h
//  Natusfera
//
//  Created by Alex Shepard on 11/20/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

//#import <GoogleOpenSource/GoogleOpenSource.h>
#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
//@interface GooglePlusAuthViewController : GTMOAuth2ViewControllerTouch //lineas comentadas por M.Lujano
//@end    //linea comentada por M.Lujano
@interface GooglePlusAuthViewController : UIViewController <GIDSignInUIDelegate>
    
@end

//reutilizo este archivo aunque no voy a utilizar el logueo de google plus M.Lujano



