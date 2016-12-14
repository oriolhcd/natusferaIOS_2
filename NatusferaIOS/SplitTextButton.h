//
//  SplitTextButton.h
//  Natusfera
//
//  Created by Alex Shepard on 5/21/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SplitTextButton : UIControl

@property UILabel *leadingTitleLabel;
@property UILabel *trailingTitleLabel;
@property UIView *separator;
@property CGFloat leadingTitleWidth;

@end
