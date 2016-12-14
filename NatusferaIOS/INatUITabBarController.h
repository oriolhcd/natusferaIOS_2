//
//  INatUITabBarController.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Taxon;
@class Project;

@interface INatUITabBarController : UITabBarController

- (void)handleUserSavedObservationNotification:(NSNotification *)notification;
- (void)setObservationsTabBadge;
- (void)triggerNewObservationFlowForTaxon:(Taxon *)taxon project:(Project *)project;
@end
