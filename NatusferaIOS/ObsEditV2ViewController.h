//
//  ConfirmObservationViewController.h
//  Natusfera
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Observation;

@interface ObsEditV2ViewController : UIViewController

@property Observation *observation;
@property BOOL shouldContinueUpdatingLocation;
@property BOOL isMakingNewObservation;
@property UITableView *tableView;

@end
