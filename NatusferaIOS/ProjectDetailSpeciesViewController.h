//
//  ProjectDetailSpeciesViewController.h
//  Natusfera
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContainedScrollViewDelegate.h"
#import "ProjectDetailV2ViewController.h"

@interface ProjectDetailSpeciesViewController : UITableViewController

@property (assign) NSInteger totalCount;
@property NSArray *speciesCounts;
@property (assign) id <ContainedScrollViewDelegate> containedScrollViewDelegate;
@property (assign) id <ProjectDetailV2Delegate> projectDetailDelegate;
@end
