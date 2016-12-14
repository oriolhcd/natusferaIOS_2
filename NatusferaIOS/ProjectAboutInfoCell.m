//
//  ProjectAboutInfoCell.m
//  Natusfera
//
//  Created by Alex Shepard on 3/22/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import "ProjectAboutInfoCell.h"

@implementation ProjectAboutInfoCell

- (void)awakeFromNib {
    // Initialization code
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)heightForRowWithInfoText:(NSString *)text inTableView:(UITableView *)tableView {
    // 20 for the margins on the left and right
    CGFloat usableWidth = tableView.bounds.size.width - 20 - 20;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:14.0f];
    
    CGRect textRect = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{ NSFontAttributeName: font }
                                         context:nil];
    
    return MAX(44, textRect.size.height + 16); // 16 for padding
}

+ (CGFloat)heightForRowWithInfoAttributedText:(NSAttributedString *)attributedText inTableView:(UITableView *)tableView {
    // 20 for the margins on the left and right
    CGFloat usableWidth = tableView.bounds.size.width - 20 - 20;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    
    CGRect textRect = [attributedText boundingRectWithSize:maxSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];

    return MAX(44, textRect.size.height + 16); // 16 for top and bottom padding around the label
}


@end
