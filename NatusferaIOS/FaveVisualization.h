//
//  FaveVisualization.h
//  Natusfera
//
//  Created by Alex Shepard on 3/8/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FaveVisualization <NSObject>

- (NSString *)userName;
- (NSInteger)userId;
- (NSURL *)userIconUrl;

- (NSDate *)createdAt;

@end
