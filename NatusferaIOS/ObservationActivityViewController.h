//
//  ObservationActivityViewController.h
//  Natusfera
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Observation;

@interface ObservationActivityViewController : UITableViewController

@property (strong, nonatomic) Observation *observation;
- (BOOL)checkForNetworkAndWarn;
@end
