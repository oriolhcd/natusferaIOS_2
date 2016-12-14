//
//  ContainedScrollViewDelegate.h
//  Natusfera
//
//  Created by Alex Shepard on 3/4/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ContainedScrollViewDelegate <NSObject>
- (void)containedScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)containedScrollViewDidReset:(UIScrollView *)scrollView;
- (void)containedScrollViewDidStopScrolling:(UIScrollView *)scrollView;
@end
