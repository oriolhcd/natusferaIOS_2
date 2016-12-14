//
//  RankedUserObsSpeciesCell.m
//  Natusfera
//
//  Created by Alex Shepard on 4/5/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "RankedUserObsSpeciesCell.h"

@implementation RankedUserObsSpeciesCell

- (void)awakeFromNib {
    self.userImageView.layer.cornerRadius = self.userImageView.bounds.size.height / 2.0f;
    self.userImageView.clipsToBounds = YES;
    self.userImageView.layer.borderWidth = 1.0f;
    self.userImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.userImageView.image = nil;

    self.observationsCountLabel.text = @"";
    self.speciesCountLabel.text = @"";
    self.userNameLabel.text = @"";
    self.rankLabel.text = @"";
}

- (void)prepareForReuse {
    self.userImageView.image = nil;
    [self.userImageView sd_cancelCurrentImageLoad];
    
    self.observationsCountLabel.text = @"";
    self.speciesCountLabel.text = @"";
    self.userNameLabel.text = @"";
    self.rankLabel.text = @"";
}

@end
