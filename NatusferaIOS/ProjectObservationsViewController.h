//
//  ProjectObservationViewController.h
//  Natusfera
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Observation;

@interface ProjectObservationsViewController : UITableViewController

@property Observation *observation;
@property NSArray *joinedProjects;
@property BOOL isReadOnly;

@end
