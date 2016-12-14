//
//  Uploadable.h
//  Natusfera
//
//  Created by Alex Shepard on 7/24/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Uploadable <NSObject>

- (NSArray *)childrenNeedingUpload;
- (BOOL)needsUpload;
+ (NSArray *)needingUpload;

@end
