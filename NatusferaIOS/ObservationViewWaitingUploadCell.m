//
//  ObservationViewCellWaitingUpload.m
//  Natusfera
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <FontAwesomeKit/FAKIonicons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObservationViewWaitingUploadCell.h"
#import "UIColor+Natusfera.h"

@implementation ObservationViewWaitingUploadCell

// would be great to do all of this autolayout stuff in the storyboard, but that means migrating the whole storyboard to AutoLayout
- (void)awakeFromNib {
    self.uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    FAKIcon *upload = [FAKIonIcons iosCloudUploadIconWithSize:30];
    [upload addAttribute:NSForegroundColorAttributeName
                   value:[UIColor inatTint]];
    [self.uploadButton setAttributedTitle:upload.attributedString
                                 forState:UIControlStateNormal];
    
    NSDictionary *views = @{
                            @
                            "uploadButton": self.uploadButton,
                            };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[uploadButton(==44)]-0-|" options:0 metrics:0 views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[uploadButton]-0-|" options:0 metrics:0 views:views]];
}

@end
