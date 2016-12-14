//
//  GuideContainerViewController.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 9/19/13.
//  Copyright (c) 2013 Natusfera. All rights reserved.
//

#import "SWRevealViewController.h"
#import "GuideXML.h"

@protocol GuideViewControllerDelegate <NSObject>
@optional
- (void)guideViewControllerDownloadedNGZForGuide:(GuideXML *)guide;
- (void)guideViewControllerDeletedNGZForGuide:(GuideXML *)guide;
@end

@interface GuideViewController : SWRevealViewController
@property (nonatomic, strong) GuideXML *guide;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *guideMenuButton;
@property (nonatomic, weak) id <GuideViewControllerDelegate> guideDelegate;
- (IBAction)clickedGuideMenuButton:(id)sender;
@end
