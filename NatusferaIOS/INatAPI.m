//
//  INatAPI.m
//  Natusfera
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import "INatAPI.h"

@implementation INatAPI

- (NSString *)apiBaseUrl {
    return @"http://natusfera.gbif.es";
}

- (void)fetch:(NSString *)path mapping:(RKObjectMapping *)mapping handler:(INatAPIFetchCompletionHandler)done {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:url
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, error);
                        });
                    } else {
                        NSError *error = nil;
                        NSArray *json = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                        
                        if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, error);
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSArray *resultsArray;
                                
                                NSArray* jsonData = [json isKindOfClass:[NSArray class]] ? json : [[NSArray alloc] initWithObjects:json, nil];
                                
                                if (jsonData != nil && [jsonData.firstObject objectForKey:@"results"] && [jsonData.firstObject objectForKey:@"total_results"]) {
                                    resultsArray = [jsonData valueForKey:@"results"];
                                }
                                else {
                                    resultsArray = (NSArray*) jsonData;
                                }
                                NSMutableArray *output = [NSMutableArray array];
                                for (id result in resultsArray) {
                                    Class mappingClass = [mapping objectClass];
                                    id target = [[mappingClass alloc] init];
                                    RKObjectMappingOperation *operation = [RKObjectMappingOperation mappingOperationFromObject:result
                                                                                                                      toObject:target
                                                                                                                   withMapping:mapping];
                                    NSError *err;
                                    [operation performMapping:&err];
                                    [output addObject:target];
                                }
                                
                                // return this immutably
                                done([NSArray arrayWithArray:output], nil);
                            });
                        }
                    }
                    
                }] resume];

    }

}


- (void)fetchWithCount:(NSString *)path mapping:(RKObjectMapping *)mapping handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithURL:url
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, 0, error);
                        });
                    } else {
                        NSError *error = nil;
                        id json = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                        
                        if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, 0, error);
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSArray *resultsArray;
                                NSInteger totalResults = 0;
                                
                                NSArray* jsonData = [json isKindOfClass:[NSArray class]] ? json : [[NSArray alloc] initWithObjects:json, nil];

                                if (jsonData != nil && [jsonData.firstObject objectForKey:@"results"] && [jsonData.firstObject objectForKey:@"total_results"]) {
                                    resultsArray = [jsonData valueForKey:@"results"];
                                    totalResults = [[jsonData valueForKey:@"total_results"] integerValue];
                                }
                                else {
                                    resultsArray = (NSArray*) jsonData;
                                    totalResults = [jsonData count];
                                }
                                
                                NSMutableArray *output = [NSMutableArray array];
                                for (id result in resultsArray) {
                                    Class mappingClass = [mapping objectClass];
                                    id target = [[mappingClass alloc] init];
                                    RKObjectMappingOperation *operation = [RKObjectMappingOperation mappingOperationFromObject:result
                                                                                                                      toObject:target
                                                                                                                   withMapping:mapping];
                                    NSError *err = nil;
                                    [operation performMapping:&err];
                                    if (!err) {
                                        [output addObject:target];
                                    }
                                }
                                // return this immutably
                                done([NSArray arrayWithArray:output], totalResults, nil);
                            });
                        }
                    }
                    
                }] resume];
        
    }
    
}


@end
