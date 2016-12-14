//
//  NSFileManager+Natusfera.m
//  Natusfera
//
//  Created by Alex Shepard on 1/5/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import "NSFileManager+Natusfera.h"

@implementation NSFileManager (Natusfera)

#pragma mark - Free Disk Space percentage

+ (CGFloat)freeDiskSpacePercentage {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        return totalFreeSpace /  (double)totalSpace;
    } else {
        return 99;
    }
}

+ (CGFloat)freeDiskSpaceMB {
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        return totalFreeSpace / 1024.0f / 1024.0f;
    } else {
        // fake it, 10GB
        return 1024.0f;
    }
}

@end
