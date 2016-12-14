//
//  AutocompleteSearchItem.m
//  Natusfera
//
//  Created by Alex Shepard on 11/12/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

#import "AutocompleteSearchItem.h"

@implementation AutocompleteSearchItem

+ (instancetype)itemWithPredicate:(NSString *)predicate action:(SearchAction)action {
    AutocompleteSearchItem *item = [[AutocompleteSearchItem alloc] init];
    item.predicate = predicate;
    item.action = action;
    return item;
}

@end
