//
//  ExploreObservationPhoto.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

#import "ExploreObservationPhoto.h"

@implementation ExploreObservationPhoto

- (NSString *)photoKey {
    return nil;
}

- (NSURL *)largePhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"large"]];
}

- (NSURL *)mediumPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"medium"]];
}

- (NSURL *)smallPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"small"]];
}

- (NSURL *)thumbPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"thumb"]];
}

- (NSString *)urlStringForSize:(NSString *)size {
    return [self.url stringByReplacingOccurrencesOfString:@"square" withString:size];
}

@end
