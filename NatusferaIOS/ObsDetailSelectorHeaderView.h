//
//  ObsDetailSelectorHeaderView.h
//  Natusfera
//
//  Created by Alex Shepard on 12/10/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ObsDetailSelectorButton.h"

@interface ObsDetailSelectorHeaderView : UITableViewHeaderFooterView

@property ObsDetailSelectorButton *infoButton;
@property ObsDetailSelectorButton *activityButton;
@property ObsDetailSelectorButton *favesButton;

@end
