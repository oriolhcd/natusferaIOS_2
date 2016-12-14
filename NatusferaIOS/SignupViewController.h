//
//  SignupViewController.h
//  Natusfera
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Partner;

@interface SignupViewController : UIViewController

@property UIImage *backgroundImage;

@property UITableView *signupTableView;
@property UILabel *termsLabel;

@property Partner *selectedPartner;
@end
