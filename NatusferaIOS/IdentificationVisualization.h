//
//  IdentificationVisualization.h
//  Natusfera
//
//  Created by Alex Shepard on 3/7/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ActivityVisualization.h"

@protocol IdentificationVisualization <ActivityVisualization>

- (NSString *)body;
- (NSDate *)date;
- (BOOL)isCurrent;

- (NSInteger)taxonId;
- (NSInteger)taxonRankLevel;
- (NSString *)taxonRank;
- (NSString *)taxonCommonName;
- (NSString *)taxonScientificName;
- (NSURL *)taxonIconUrl;

- (NSString *)userName;
- (NSInteger)userId;
- (NSURL *)userIconUrl;

@end
