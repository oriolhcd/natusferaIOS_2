//
//  ExploreMapViewController.h
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ExploreObservationVisualizerViewController.h"
#import "ExploreContainerViewController.h"

@interface ExploreMapViewController : ExploreObservationVisualizerViewController <ExploreViewControllerControlIcon>

- (void)mapShouldZoomToCoordinates:(CLLocationCoordinate2D)coords showUserLocation:(BOOL)showUserLocation;

@end
