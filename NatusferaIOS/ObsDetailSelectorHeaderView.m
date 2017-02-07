//
//  ObsDetailSelectorHeaderView.m
//  Natusfera
//
//  Created by Alex Shepard on 12/10/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObsDetailSelectorHeaderView.h"
#import "UIColor+Natusfera.h"

@implementation ObsDetailSelectorHeaderView


- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        
        self.infoButton = ({
            ObsDetailSelectorButton *button = [ObsDetailSelectorButton buttonWithSelectorType:ObsDetailSelectorButtonTypeInfo];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            
            button.enabled = YES;
            
            button;
        });
        
        self.activityButton = ({
            ObsDetailSelectorButton *button = [ObsDetailSelectorButton buttonWithSelectorType:ObsDetailSelectorButtonTypeActivity];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            
            button.enabled = YES;

            button;
        });
        
        UIView *edge = ({
            UIView *view = [UIView new];
            view.frame = CGRectZero;
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
            
            view;
        });
        [self addSubview:edge];
        
        [self addSubview:self.infoButton];
        [self addSubview:self.activityButton];
        
        NSDictionary *views = @{
                                @"info": self.infoButton,
                                @"activity": self.activityButton,
                                @"edge": edge,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[info]-[activity(==info)]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[edge]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[info]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[activity]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[edge(==0.5)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        

    }
    
    return self;
}

- (void)prepareForReuse {
    [@[ self.infoButton, self.activityButton ] enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL * _Nonnull stop) {
        button.enabled = YES;
    }];
}

@end
