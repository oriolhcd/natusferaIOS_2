//
//  ProjectObsPhotoCell.m
//  Natusfera
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "ProjectObsPhotoCell.h"

@implementation ProjectObsPhotoCell

- (void)prepareForReuse {
    self.photoImageView.image = nil;
    [self.photoImageView sd_cancelCurrentImageLoad];
    self.obsText.text = @"";
}

@end
