//
//  TaxonPhotoCell.m
//  Natusfera
//
//  Created by Alex Shepard on 3/9/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import "TaxonPhotoCell.h"

@implementation TaxonPhotoCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)prepareForReuse {
    [self.creditsButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
