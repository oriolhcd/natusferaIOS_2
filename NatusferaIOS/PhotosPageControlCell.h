//
//  PhotosPageControlCell.h
//  Natusfera
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotosPageControlCell : UITableViewCell

@property IBOutlet UIPageControl *pageControl;
@property IBOutlet UIImageView *iv;
@property IBOutlet UIView *captiveContainer;
@property IBOutlet UIButton *captiveInfoButton;
@property IBOutlet UIButton *shareButton;

@end
