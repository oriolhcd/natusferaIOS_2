//
//  ProjectDetailViewController.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "ProjectUser.h"
//añadido por M.Lujano:29/06/2016
#import "GuideXML.h"


@interface ProjectDetailViewController : UITableViewController <RKObjectLoaderDelegate, UIAlertViewDelegate>
//la siguiente property ha sido añadida por M.Lujano:29/06/2016
@property (nonatomic, strong)GuideXML *guide;
@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) ProjectUser *projectUser;
@property (nonatomic, strong) NSMutableDictionary *sectionHeaderViews;
@property (weak, nonatomic) IBOutlet UIImageView *projectIcon;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *projectTitle;
- (IBAction)clickedViewButton:(id)sender;
- (IBAction)clickedJoin:(id)sender;
- (IBAction)clickedClose:(id)sender;
- (void)join;
- (void)leave;
- (void)setupJoinButton;
- (NSInteger)heightForHTML:(NSString *)html;
@end
