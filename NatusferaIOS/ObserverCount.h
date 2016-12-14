//
//  ObserverCount.h
//  Natusfera
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ExplorePerson;

@interface ObserverCount : NSObject

@property NSString *observerIconUrl;
@property NSString *observerName;
@property NSInteger observerId;
@property NSInteger observationCount;
@property NSInteger speciesCount;

@end
