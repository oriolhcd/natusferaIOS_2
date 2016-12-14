//
//  ObsDetailMapCell.m
//  Natusfera
//
//  Created by Alex Shepard on 12/8/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import "ObsDetailMapCell.h"
#import "FAKNatusfera.h"

@implementation ObsDetailMapCell

- (void)awakeFromNib {
    // Initialization code
    
    self.locationNameContainer.layer.cornerRadius = 1.0f;
    self.locationNameContainer.clipsToBounds = YES;
    
    self.noLocationLabel.attributedText = ({
        FAKIcon *noLocation = [FAKNatusfera noLocationIconWithSize:80];
        [noLocation addAttribute:NSForegroundColorAttributeName
                           value:[UIColor whiteColor]];
        
        noLocation.attributedString;
    });
    
    // ios8 and later
    if ([self.mapView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.mapView setLayoutMargins:UIEdgeInsetsMake(30, 30, 45, 50)];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    self.locationNameLabel.text = nil;
    self.mapView.hidden = NO;
    self.noLocationLabel.hidden = YES;
    [self.mapView removeAnnotations:self.mapView.annotations];
    self.geoprivacyLabel.text = nil;
}

@end
