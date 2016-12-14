//
//  NSFileManager+Natusfera.h
//  Natusfera
//
//  Created by Alex Shepard on 1/5/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Natusfera)

+ (CGFloat)freeDiskSpacePercentage;
+ (CGFloat)freeDiskSpaceMB;

@end
