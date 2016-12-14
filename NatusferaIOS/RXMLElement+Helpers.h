//
//  RXMLElement+Helpers.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 9/16/13.
//  Copyright (c) 2013 Natusfera. All rights reserved.
//

#import "RXMLElement.h"

@interface RXMLElement (Helpers)
- (NSString *)xmlString;
- (RXMLElement *)atXPath:(NSString *)xpath;
- (RXMLElement *)atXPath:(NSString *)xpath;
- (NSDictionary *)namespaces;
- (void)iterateWithXPath:(NSString *)xpath usingBlock:(void (^)(RXMLElement *))blk;
@end
