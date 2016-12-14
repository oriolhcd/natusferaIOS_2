//
//  ObservationViewCellUploading.h
//  Natusfera
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationViewCell.h"

@interface ObservationViewUploadingCell : ObservationViewCell

@property IBOutlet UIProgressView *progressView;
@property IBOutlet UILabel *dateLabel;

@end
