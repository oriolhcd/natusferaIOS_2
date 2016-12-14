//
//  Observation+AddAssets.h
//  Natusfera
//
//  Created by Alex Shepard on 3/27/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import "Observation.h"

@class ObservationPhoto;

@interface Observation (AddAssets)
- (void)addAssets:(NSArray *)assets;
- (void)addAssets:(NSArray *)assets afterEach:(void(^)(ObservationPhoto *))afterEachBlock;
@end
