//
//  RankedUserObsSpeciesCell.h
//  Natusfera
//
//  Created by Alex Shepard on 4/5/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RankedUserObsSpeciesCell : UITableViewCell

@property IBOutlet UILabel *rankLabel;
@property IBOutlet UIImageView *userImageView;
@property IBOutlet UILabel *userNameLabel;
@property IBOutlet UILabel *observationsCountLabel;
@property IBOutlet UILabel *speciesCountLabel;

@end
