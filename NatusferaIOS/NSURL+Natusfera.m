//
//  NSURL+Natusfera.m
//  Natusfera
//
//  Created by Alex Shepard on 6/18/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import "NSURL+Natusfera.h"

@implementation NSURL (Natusfera)

+ (instancetype)inat_baseURL {
    NSString *configuredBaseUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kInatCustomBaseURLStringKey];
    if (configuredBaseUrl) {
        return [NSURL URLWithString:configuredBaseUrl];
    } else {
        return [NSURL URLWithString:INatBaseURL];
    }
}

+ (instancetype)inat_baseURLForAuthentication {
    // partner sites won't do authentication for now
    return [NSURL URLWithString:INatBaseURL];
}

@end
