//
//  MultiImageView.h
//  Natusfera
//
//  Created by Alex Shepard on 2/26/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MultiImageView : UIView

@property NSArray *images;
@property CGFloat borderWidth;
@property UIColor *borderColor;

@property (readonly) NSArray *imageViews;

@end
