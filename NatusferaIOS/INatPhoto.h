//
//  INatPhoto.h
//  Natusfera
//
//  Created by Alex Shepard on 5/8/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol INatPhoto <NSObject>

- (NSURL *)largePhotoUrl;
- (NSURL *)mediumPhotoUrl;
- (NSURL *)smallPhotoUrl;
- (NSURL *)thumbPhotoUrl;

- (NSString *)photoKey;

@end
