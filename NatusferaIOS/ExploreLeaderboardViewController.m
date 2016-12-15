//
//  ExploreLeaderboardViewController.m
//  Natusfera
//
//  Created by Alex Shepard on 2/17/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/BlocksKit.h>

#import "ExploreLeaderboardViewController.h"
#import "ExploreObservationsController.h"
#import "ExploreLeaderboardCell.h"
#import "ExploreLeaderboardHeader.h"
#import "Taxon.h"
#import "Analytics.h"
#import "ObserverCount.h"
#import "UIImage+Natusfera.h"

static NSString *LeaderboardCellReuseID = @"LeaderboardCell";

@interface ExploreLeaderboardViewController () <UITableViewDataSource,UITableViewDelegate> {
    UITableView *leaderboardTableView;
    NSArray *leaderboard;
    UIActivityIndicatorView *loadingSpinner;
}
@end

@implementation ExploreLeaderboardViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    leaderboard = @[];
    
    self.title = NSLocalizedString(@"Leaderboard", @"Title for leaderboard page.");
    
    leaderboardTableView = ({
        UITableView *tv =[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        [tv registerClass:[ExploreLeaderboardCell class] forCellReuseIdentifier:LeaderboardCellReuseID];
        tv.separatorColor = [UIColor darkGrayColor];
        
        tv.delegate = self;
        tv.dataSource = self;
        
        tv.tableFooterView = [UIView new];
        
        tv;
    });
    [self.view addSubview:leaderboardTableView];
    
    loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    loadingSpinner.hidden = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingSpinner];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leaderboardTableView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leaderboardTableView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leaderboardTableView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leaderboardTableView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[Analytics sharedClient] event:kAnalyticsEventNavigateExploreLeaderboard];
    
    loadingSpinner.hidden = NO;
    [loadingSpinner startAnimating];

    [self.observationsController loadLeaderboardCompletion:^(NSArray *results, NSError *error) {
                                            
                                              if (error) {
                                                  [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error loading leaderboard: %@",
                                                                                      error.localizedDescription]];
                                                  [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error loading leaderboard", @"error loading leaderboard title")
                                                                              message:error.localizedDescription
                                                                             delegate:nil
                                                                    cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                    otherButtonTitles:nil] show];

                                                  return;
                                              }
                                              
                                              leaderboard = results;

                                              [leaderboardTableView reloadData];
                                              
                                              [loadingSpinner stopAnimating];
                                              loadingSpinner.hidden = YES;
                                          }];
}

#pragma mark - UITableView delegate/datasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return leaderboard.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreLeaderboardCell *cell = (ExploreLeaderboardCell *)[tableView dequeueReusableCellWithIdentifier:LeaderboardCellReuseID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self configureCell:cell forIndexPath:indexPath];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (void)configureCell:(ExploreLeaderboardCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    ObserverCount *count = [leaderboard objectAtIndex:indexPath.item];
    NSInteger obsCount = count.observationCount;
    NSInteger speciesCount = count.speciesCount;
    NSString *username = count.observerName;
    NSString *userIconUrl = count.observerIconUrl;
    
    cell.username.text = username;
    
    // the leaderboard API call can return users who are on the species leaderboard but not the
    // obs leaderboard, leaving them with 0 apparent observations in the JSON. this is obviously
    // incorrect, but we don't want to do another API call for every row, so just show * like on
    // the web.
    
    NSString *observations = NSLocalizedString(@"Observations", "");
    if (obsCount > 0) {
        cell.observationCount.text = [NSString stringWithFormat:@"%@: %ld", observations, (long)obsCount];
    } else {
        cell.observationCount.text = [NSString stringWithFormat:@"%@: *", observations];
    }
    
    NSString *species = NSLocalizedString(@"Species", "");
    if (speciesCount > 0) {
        cell.speciesCount.text = [NSString stringWithFormat:@"%@: %ld", species, (long)speciesCount];
    } else {
        cell.speciesCount.text = [NSString stringWithFormat:@"%@: *", species];
    }
    
    if (![userIconUrl isEqual:[NSNull null]] && ![userIconUrl isEqualToString:@""]) {
        [cell.userIcon sd_setImageWithURL:[NSURL URLWithString:userIconUrl]];
    } else {
        cell.userIcon.image = [UIImage inat_defaultUserImage];
    }
        
    cell.rank.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row + 1];
}

@end
