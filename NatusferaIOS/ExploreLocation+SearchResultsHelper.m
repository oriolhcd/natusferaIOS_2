//
//  ExploreLocation+SearchResultsHelper.m
//  Natusfera
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

#import "ExploreLocation+SearchResultsHelper.h"

@implementation ExploreLocation (SearchResultsHelper)

- (NSString *)searchResult_Title {
    return self.name;
}

- (NSString *)searchResult_SubTitle {
    return self.placeTypeName;
}

@end
