//
//  SpeciesCountCell.h
//  Natusfera
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpeciesCountCell : UITableViewCell

@property IBOutlet UIImageView *taxonImageView;
@property IBOutlet UILabel *taxonNameLabel;
@property IBOutlet UILabel *taxonSecondaryNameLabel;
@property IBOutlet UILabel *countLabel;

@end
