//
//  EditableTextViewCell.h
//  Natusfera
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditableTextFieldCell : UITableViewCell

@property UITextField *textField;

@property NSAttributedString *activeLeftAttributedString;
@property NSAttributedString *inactiveLeftAttributedString;

@end
