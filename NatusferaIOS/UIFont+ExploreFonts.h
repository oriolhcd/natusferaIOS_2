//
//  UIFont+ExploreFonts.h
//  Natusfera
//
//  Created by Alex Shepard on 10/28/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (ExploreFonts)

+ (instancetype)fontForTaxonRankName:(NSString *)rankName ofSize:(CGFloat)size;

@end
