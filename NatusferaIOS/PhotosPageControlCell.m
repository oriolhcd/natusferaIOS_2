//
//  PhotosPageControlCell.m
//  Natusfera
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonicons.h>

#import "PhotosPageControlCell.h"

@implementation PhotosPageControlCell

- (void)awakeFromNib {
    // Initialization code
    
    self.shareButton.layer.cornerRadius = 31.0 / 2;
    self.shareButton.clipsToBounds = YES;
    self.shareButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
    
    FAKIcon *share = [FAKIonIcons iosUploadOutlineIconWithSize:20];
    [share addAttribute:NSForegroundColorAttributeName
                  value:[UIColor whiteColor]];
    [self.shareButton setAttributedTitle:share.attributedString
                                forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.iv sd_cancelCurrentImageLoad];
    self.pageControl.currentPage = 0;
    self.captiveContainer.hidden = YES;
    // clear all targets/actions
    [self.captiveInfoButton removeTarget:nil
                                  action:NULL
                        forControlEvents:UIControlEventAllEvents];
    [self.shareButton removeTarget:nil
                            action:NULL
                  forControlEvents:UIControlEventAllEvents];
}

@end
