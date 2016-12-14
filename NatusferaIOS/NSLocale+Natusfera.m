//
//  NSLocale+Natusfera.m
//  Natusfera
//
//  Created by Alex Shepard on 7/7/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import "NSLocale+Natusfera.h"

@implementation NSLocale (Natusfera)

+ (NSString *)inat_serverFormattedLocale {
    // iOS gives us en_US, server expects en-US
    NSString *localeString = [[NSLocale currentLocale] localeIdentifier];
    NSString *serverLocaleIdentifier = [localeString stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    return serverLocaleIdentifier;
}

@end
