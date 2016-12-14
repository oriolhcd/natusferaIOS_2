//
//  ObsDetailTaxonCell.m
//  Natusfera
//
//  Created by Alex Shepard on 12/16/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "ObsDetailTaxonCell.h"

@implementation ObsDetailTaxonCell

- (void)awakeFromNib {
    // Initialization code
    
    self.taxonImageView.layer.borderWidth = 0.5f;
    self.taxonImageView.layer.borderColor = [UIColor colorWithHexString:@"#777777"].CGColor;
    self.taxonImageView.layer.cornerRadius = 3.0f;
    self.taxonImageView.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    self.taxonNameLabel.text = nil;
    self.taxonNameLabel.font = [UIFont systemFontOfSize:17];
    self.taxonSecondaryNameLabel.text = nil;
    self.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
    
    [self.taxonImageView sd_cancelCurrentImageLoad];
    self.taxonImageView.image = nil;
}

@end
