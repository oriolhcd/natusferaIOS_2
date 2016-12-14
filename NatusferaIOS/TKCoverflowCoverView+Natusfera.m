//
//  TKCoverflowCoverView+Natusfera.m
//  Natusfera
//
//  Created by Ken-ichi Ueda on 4/2/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

#import "TKCoverflowCoverView+Natusfera.h"

@implementation TKCoverflowCoverView (Natusfera)

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletionBlock)completion
{
    [self.imageView sd_setImageWithURL:url
                      placeholderImage:placeholder
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 completion(image, error, cacheType, imageURL);
                             }];
}

@end
