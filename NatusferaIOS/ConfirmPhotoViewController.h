//
//  ConfirmPhotoViewController.h
//  Natusfera
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Taxon;
@class Project;
@class MultiImageView;

@interface ConfirmPhotoViewController : UIViewController

@property UIImage *image;
@property NSArray *assets;
@property NSDictionary *metadata;
@property BOOL shouldContinueUpdatingLocation;

@property Taxon *taxon;
@property Project *project;

@property (nonatomic, copy) void(^confirmFollowUpAction)(NSArray *confirmedAssets);

@property MultiImageView *multiImageView;

@end
