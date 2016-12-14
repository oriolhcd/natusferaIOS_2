//
//  ObsDetailV2ViewController.h
//  Natusfera
//
//  Created by Alex Shepard on 11/17/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ObservationVisualization.h"
#import "Uploadable.h"

@interface ObsDetailV2ViewController : UIViewController

@property id <ObservationVisualization, Uploadable> observation;

@end
