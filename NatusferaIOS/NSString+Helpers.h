//
//  NSString+Helpers.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 3/13/12.
//  Copyright (c) 2012 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Helpers)

- (NSString *)underscore;
- (NSString *)pluralize;
- (NSString *)humanize;
-(NSString *) stringByStrippingHTML;
@end
