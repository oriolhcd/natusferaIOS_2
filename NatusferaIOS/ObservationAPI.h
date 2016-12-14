//
//  ObservationAPI.h
//  Natusfera
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import "INatAPI.h"

@interface ObservationAPI : INatAPI

- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionHandler)done;

@end
