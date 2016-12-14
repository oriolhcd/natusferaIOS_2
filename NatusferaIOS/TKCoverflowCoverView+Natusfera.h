//
//  TKCoverflowCoverView+Natusfera.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 4/2/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//
// Add some methods to load remote images

#import <TapkuLibrary/TapkuLibrary.h>
#import "UIImageView+WebCache.h"

@interface TKCoverflowCoverView (Natusfera)
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletionBlock)completion;
@end
