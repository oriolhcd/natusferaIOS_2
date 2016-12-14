//
//  ObservationViewCell.h
//  Natusfera
//
//  Created by Eldad Ohana on 7/2/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationViewCell.h"

static const int ObservationCellImageTag = 5;
static const int ObservationCellTitleTag = 1;
static const int ObservationCellSubTitleTag = 2;
static const int ObservationCellUpperRightTag = 3;
static const int ObservationCellLowerRightTag = 4;
static const int ObservationCellActivityButtonTag = 6;
static const int ObservationCellActivityInteractiveButtonTag = 7;

@interface ObservationViewNormalCell : ObservationViewCell

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *interactiveActivityButton;
@property (weak, nonatomic) IBOutlet UIButton *activityButton;

@end
