//
//  ProjectDetailPageViewController.m
//  Natusfera
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ProjectDetailPageViewController.h"
#import "ProjectsAPI.h"
#import "ProjectDetailObservationsViewController.h"
#import "ProjectDetailSpeciesViewController.h"
#import "ProjectDetailObserversViewController.h"
#import "ProjectDetailIdentifiersViewController.h"
#import "ContainedScrollViewDelegate.h"
#import "UIColor+Natusfera.h"

@interface ViewPagerController ()
- (void)selectTabAtIndex:(NSUInteger)index didSwipe:(BOOL)didSwipe;
@end

@interface ProjectDetailPageViewController () <ViewPagerDataSource, ViewPagerDelegate>
@property ProjectsAPI *api;

@property ProjectDetailObservationsViewController *projObservationsVC;
@property ProjectDetailSpeciesViewController *projSpeciesVC;
@property ProjectDetailObserversViewController *projObserversVC;
@property ProjectDetailIdentifiersViewController *projIdentifiersVC;

@property NSInteger numObservations;
@property NSInteger numSpecies;
@property NSInteger numObservers;
@property NSInteger numIdentifers;

@end

@implementation ProjectDetailPageViewController

-(void)viewDidLoad {
    self.numObservations = 0;
    
    self.projObservationsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"projObservationsVC"];
    [self addChildViewController:self.projObservationsVC];
    self.projObservationsVC.projectDetailDelegate = self.projectDetailDelegate;
    self.projObservationsVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
    
    self.projObservationsVC.view.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.projObservationsVC.view];
    [self.projObservationsVC.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0.0];
    [NSLayoutConstraint activateConstraints:@[
                                              [self.projObservationsVC.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0.0],
                                              [self.projObservationsVC.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0.0],
                                              [self.projObservationsVC.view.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0.0],
                                              [self.projObservationsVC.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0.0]
                                              ]];
    [self.projObservationsVC didMoveToParentViewController:self];
    
    self.api = [[ProjectsAPI alloc] init];
    __weak typeof(self)weakSelf = self;
    [self.api observationsForProject:self.project handler:^(NSArray *results, NSInteger totalCount, NSError *error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.projObservationsVC.observations = (results != nil) ? results : [[NSArray alloc] init];
        strongSelf.numObservations = totalCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.projObservationsVC.collectionView reloadData];
        });
    }];
}

@end
