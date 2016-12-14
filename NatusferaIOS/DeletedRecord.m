//
//  DeletedRecord.m
//  Natusfera
//
//  Created by Ken-ichi Ueda on 3/22/12.
//  Copyright (c) 2012 Natusfera. All rights reserved.
//

#import "DeletedRecord.h"


@implementation DeletedRecord

@dynamic recordID;
@dynamic modelName;

+ (NSArray *)needingSync
{
    return [self allObjects];
}

+ (NSInteger)needingSyncCount
{
    return self.needingSync.count;
}

@end
