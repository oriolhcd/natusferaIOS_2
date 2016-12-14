//
//  Activity.h
//  Natusfera
//
//  Created by Alex Shepard on 11/20/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import "INatModel.h"

#import "ActivityVisualization.h"

@class User, Observation;

@interface Activity : INatModel <ActivityVisualization>

@property (nonatomic, retain) NSString *body;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Observation *observation;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSURL *userIconUrl;

@property (nonatomic, assign) NSInteger userId;
@end
