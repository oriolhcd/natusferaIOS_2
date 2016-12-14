//
//  NSAttributedString+InatHelpers.h
//  Natusfera
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (InatHelpers)

+ (instancetype)inat_attrStrWithBaseStr:(NSString *)baseStr
                              baseAttrs:(NSDictionary *)baseAttrs
                               emSubstr:(NSString *)emSubStr
                                emAttrs:(NSDictionary *)emAttrs;

@end
