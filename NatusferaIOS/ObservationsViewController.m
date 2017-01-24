//
//  ObservationsViewController.m
//  Natusfera
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 Natusfera. All rights reserved.
//

#import <QBImagePickerController/QBImagePickerController.h>
#import <ImageIO/ImageIO.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <CustomIOSAlertView/CustomIOSAlertView.h>
#import <SDWebImage/UIButton+WebCache.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <YLMoment/YLMoment.h>

#import "ObservationsViewController.h"
#import "LoginController.h"
#import "Observation.h"
#import "ObservationFieldValue.h"
#import "ObservationPageViewController.h"
#import "ObservationPhoto.h"
#import "ProjectObservation.h"
#import "Project.h"
#import "ImageStore.h"
#import "INatUITabBarController.h"
#import "NatusferaAppDelegate.h"
#import "RefreshControl.h"
#import "ObservationActivityViewController.h"
#import "UIImageView+WebCache.h"
#import "UIColor+Natusfera.h"
#import "Analytics.h"
#import "User.h"
#import "MeHeaderView.h"
#import "AnonHeaderView.h"
#import "INatWebController.h"
#import "SignupSplashViewController.h"
#import "LoginViewController.h"
#import "NatusferaAppDelegate+TransitionAnimators.h"
#import "UploadManagerNotificationDelegate.h"
#import "ObservationViewNormalCell.h"
#import "ObservationViewUploadingCell.h"
#import "ObservationViewWaitingUploadCell.h"
#import "ObservationViewErrorCell.h"
#import "ObservationDetailViewController.h"
#import "DeletedRecord.h"
#import "UploadManager.h"
#import "ObsDetailV2ViewController.h"

@interface ObservationsViewController () <NSFetchedResultsControllerDelegate, UploadManagerNotificationDelegate, ObservationDetailViewControllerDelegate, UIAlertViewDelegate, RKObjectLoaderDelegate, RKRequestDelegate, RKObjectMapperDelegate> {
    
    

    NSFetchedResultsController *_fetchedResultsController;
}



@property RKObjectLoader *meObjectLoader;
@property MeHeaderView *meHeader;
@property (nonatomic, strong) NSDate *lastRefreshAt;
@property (readonly) NSFetchedResultsController *fetchedResultsController;
@property UIView *noContentView;
@property UILabel *noObservationsLabel;
@property UIImageView *noObservationsImageView;
@property NSMutableDictionary *uploadProgress;

@end

@implementation ObservationsViewController

- (void)presentSignupSplashWithReason:(NSString *)reason {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                     withProperties:@{ @"From": @"Observations" }];

    SignupSplashViewController *splash = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
    splash.cancellable = YES;
    splash.reason = reason;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:splash];
    // for sizzle
    nav.delegate = (NatusferaAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.tabBarController presentViewController:nav animated:YES completion:nil];
}

- (void)presentAutouploadAlert {
    
    if (![UIAlertController class]) {
        return;
    }
    
    [[UIView appearanceWhenContainedIn:[UIAlertController class], nil] setBackgroundColor:[UIColor inatTint]];
    
    // existing users see a one-time autoupload notice
    NSString *alertTitle = NSLocalizedString(@"Introducing Auto Upload!", @"title of autoupload introduction alert view");
    
    NSAttributedString *attrTitleText = [[NSAttributedString alloc] initWithString:alertTitle
                                                                        attributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                      NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
                                                                                      }];

    NSString *alertMsg = NSLocalizedString(@"Turn on Auto Upload and your observations will be automatically uploaded to Natusfera.",
                                           @"message of autoupload introduction alert view");
    NSAttributedString *attrMsg = [[NSAttributedString alloc] initWithString:alertMsg
                                                                  attributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] }];

    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert setValue:attrTitleText forKey:@"attributedTitle"];
    [alert setValue:attrMsg forKey:@"attributedMessage"];
    
    // sets the color of the alert action cells only
    alert.view.tintColor = [UIColor whiteColor];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No Thanks", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Turn On", @"button title to turn on autoupload")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                // enable the autoupload setting
                                                [[NSUserDefaults standardUserDefaults] setBool:YES
                                                                                        forKey:kInatAutouploadPrefKey];
                                                [[NSUserDefaults standardUserDefaults] synchronize];
                                                
                                                // kick off autoupload if appropriate
                                                NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                UploadManager *uploadManager = appDelegate.loginController.uploadManager;
                                                if ([uploadManager shouldAutoupload]) {
                                                    if (uploadManager.isNetworkAvailableForUpload) {
                                                        [uploadManager autouploadPendingContent];
                                                    } else {
                                                        if (uploadManager.shouldNotifyAboutNetworkState) {
                                                            [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Network Unavailable", nil)
                                                                                       dismissAfter:4];
                                                        }
                                                    }
                                                }
                                                
                                                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                            }]];
    [self.navigationController presentViewController:alert animated:YES completion:^{
        [[UIView appearanceWhenContainedIn:[UIAlertController class], nil] setBackgroundColor:nil];
    }];

}

- (void)uploadOneObservation:(UIButton *)button {
    CGPoint buttonCenter = button.center;
    CGPoint translatedCenter = [self.tableView convertPoint:buttonCenter fromView:button.superview];
    NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:translatedCenter];
    
    Observation *observation = [self.fetchedResultsController objectAtIndexPath:ip];
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncObservation
                     withProperties:@{
                                      @"Via": @"Manual Single Upload",
                                      @"numDeletes": @(0),
                                      @"numUploads": @(1),
                                      }];

    [self uploadDeletes:@[]
                uploads:@[ observation ]];
}

- (IBAction)sync:(id)sender {
    
    if (self.isSyncing) {
        [self stopSyncPressed];
        return;
    }
    
    NSMutableArray *recordsToDelete = [NSMutableArray array];
    for (Class class in @[ [Observation class], [ObservationPhoto class], [ObservationFieldValue class], [ProjectObservation class] ]) {
        [recordsToDelete addObjectsFromArray:[DeletedRecord objectsWithPredicate:[NSPredicate predicateWithFormat:@"modelName = %@", \
                                                                                  NSStringFromClass(class)]]];
    }
    NSArray *recordsToUpload = [Observation needingUpload];
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncObservation
                     withProperties:@{
                                      @"Via": @"Manual Full Upload",
                                      @"numDeletes": @(recordsToDelete.count),
                                      @"numUploads": @(recordsToUpload.count),
                                      }];


    [self uploadDeletes:recordsToDelete
                uploads:[Observation needingUpload]];
}

- (void)uploadDeletes:(NSArray *)recordsToDelete uploads:(NSArray *)observationsToUpload {
    
    if (self.isSyncing) {
        return;
    }
    
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                     message:NSLocalizedString(@"You must be connected to the Internet to upload to Natusfera.gbif.es",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:INatTokenPrefKey]) {
        [self presentSignupSplashWithReason:NSLocalizedString(@"You must be logged in to upload.", @"This is an explanation for why the upload button triggers a login prompt.")];
        return;
    }

    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    
    [uploader syncDeletedRecords:recordsToDelete
          thenUploadObservations:observationsToUpload];
}

- (void)stopSyncPressed {
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                                      @"Via": @"Stop Upload Button",
                                      }];
    
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    [uploader cancelSyncsAndUploads];
}

- (void)syncStopped
{
    // allow sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    // stop any persistent upload animations
    [self.meHeader stopAnimatingUpload];
    
    // reload tableview
    [[self tableView] reloadData];
    
    // update tab bar UI
    [self updateSyncBadge];
}

- (BOOL)isSyncing {
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.loginController.uploadManager.isUploading;
    return [UIApplication sharedApplication].isIdleTimerDisabled;
}

/**
 If sync is pending, -pullToRefresh should sync rather than refreshData.
 The app will always treat the server as the ultimate source of truth for 
 observations. If sync is pending on a local observation, fetching
 from the server would over-write locally changed values. Avoid that by
 always finishing sync before refresh.
 */
- (void)pullToRefresh {
    [self refreshRequestedNotify:YES];
}

- (void)refreshRequestedNotify:(BOOL)notify {
    
    if (![[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined] ||
        ![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {\
        
        if (notify) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network unavailable", nil)
                                        message:NSLocalizedString(@"You must be connected to the Internet to upload to Natusfera.gbfi.es", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];

            [self.refreshControl endRefreshing];
        }
        
        return;
    }
    
    NSInteger itemsToUpload = [[Observation needingUpload] count] + [Observation deletedRecordCount];
    itemsToUpload += [ObservationPhoto deletedRecordCount];
    itemsToUpload += [ProjectObservation deletedRecordCount];
    itemsToUpload += [ObservationFieldValue deletedRecordCount];
    
    if (itemsToUpload > 0) {
        // no implicit upload
        if (!notify) { return; }
        
        [[Analytics sharedClient] event:kAnalyticsEventObservationsPullToRefresh
                         withProperties:@{ @"ActionTaken" : @"Sync" }];
        [self.refreshControl endRefreshing];
        [self sync:nil];
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventObservationsPullToRefresh
                         withProperties:@{ @"ActionTaken" : @"RefreshData" }];
        [self refreshData];
    }
}

- (void)refreshData
{
    
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
    //comentado por M.Lujano:24/06/2016
    //NSString *path = [NSString stringWithFormat:@"/observations/%@.json?extra=observation_photos,projects,fields&per_page=10", username];
    
	if (username.length) {
        [[Analytics sharedClient] debugLog:@"Network - Refresh 10 recent observations"];
        
        //las siguientes lineas de código has sido comentadas por M.Lujano:26-09-2016
        //[[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@.json?extra=observation_photos,projects,fields&per_page=10", username]
        //                                             objectMapping:[Observation mapping]
        //                                                  delegate:self];
        
        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@.json?extra=observation_photos,projects,fields&per_page=10", username]
                                                        usingBlock:^(RKObjectLoader *loader){
                                                            loader.objectMapping=[Observation mapping];
                                                            loader.delegate=self;
                                                        }];
         

        
        
        //comentado por M.Lujano:08/06/2016
        //[[RKObjectManager sharedManager] loadObjectAtResourcePath:path usingBlock:^(RKObjectLoader *loader)
        // {
        //     loader.objectMapping=[Observation mapping];
        //     loader.delegate=self;
        // }];
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[Analytics sharedClient] debugLog:@"Network - Refresh 200 recent observations"];
            
            //las siguientes lineas de codigo han sido comentadas por M.Lujano:26-09-2016
            //[[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@.json?extra=observation_photos,projects,fields", username]
              //                                           objectMapping:[Observation mapping]
                //                                              delegate:self];
            
            [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@.json?extra=observation_photos,projects,fields", username]
                                                            usingBlock:^(RKObjectLoader *loader){
                                                                loader.objectMapping =[Observation mapping];
                                                                loader.delegate=self;
                                                            }];
            
        });

        [self loadUserForHeader];
        self.lastRefreshAt = [NSDate date];
	}
}

- (void)checkForDeleted {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
	if (username.length) {
		
		NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:INatLastDeletedSync];
		if (!lastSyncDate) {
			// have never synced; use unix timestamp date of 0
			lastSyncDate = [NSDate dateWithTimeIntervalSince1970:0];
		}
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		[dateFormatter setLocale:enUSPOSIXLocale];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

		NSString *iso8601String = [dateFormatter stringFromDate:lastSyncDate];
		
        [[Analytics sharedClient] debugLog:@"Network - Get My Recent Observations"];
		[[RKClient sharedClient] get:[NSString stringWithFormat:@"/observations/%@?updated_since=%@", username, iso8601String] delegate:self];
	}
}

- (void)checkNewActivity
{
    RKReachabilityObserver *reachability = [[RKClient sharedClient] reachabilityObserver];
    if ([reachability isReachabilityDetermined] && [reachability isNetworkReachable] ) {
        [[Analytics sharedClient] debugLog:@"Network - Get My Updates Activity"];
        [[RKClient sharedClient] get:@"/users/new_updates.json?notifier_types=Identification,Comment&skip_view=true&resource_type=Observation"
                            delegate:self];
    }
}

- (void)reload
{
	[self checkEmpty];
}

- (void)updateSyncBadge {
    [((INatUITabBarController *)self.tabBarController) setObservationsTabBadge];
}

- (void)checkEmpty
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];      // only one section of observations in our tableview

    if ([sectionInfo numberOfObjects] == 0) {

        if (!self.noContentView) {
            self.noContentView = ({
                
                
                // leave room for the header
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 100.0f,
                                                                        self.tableView.frame.size.width,
                                                                        self.tableView.frame.size.height - 100.0f)];
                view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
                
                view.backgroundColor = [UIColor whiteColor];
                
                self.noObservationsLabel = ({
                    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                    label.translatesAutoresizingMaskIntoConstraints = NO;
                    
                    label.textColor = [UIColor grayColor];
                    label.text = NSLocalizedString(@"Looks like you have no observations.", @"Notice to display to the user on the Me tab when they have no observations");
                    label.font = [UIFont systemFontOfSize:14.0f];
                    label.numberOfLines = 2;
                    label.textAlignment = NSTextAlignmentCenter;
                    
                    label;
                });
                [view addSubview:self.noObservationsLabel];
                
                self.noObservationsImageView = ({
                    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
                    iv.translatesAutoresizingMaskIntoConstraints = NO;
                    
                    iv.contentMode = UIViewContentModeScaleAspectFit;
                    iv.image = [[UIImage imageNamed:@"binocs"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    iv.tintColor = [UIColor lightGrayColor];
                    
                    iv;
                });
                [view addSubview:self.noObservationsImageView];
                
                NSDictionary *views = @{
                                        @"bottomLayout": self.bottomLayoutGuide,
                                        @"noObservations": self.noObservationsLabel,
                                        @"binocs": self.noObservationsImageView,
                                        };
                
                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[noObservations]-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];
                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[binocs]-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];

                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[noObservations(==40)]-0-[binocs]-100-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];

                
                view;
            });
            
        }
        [self.view insertSubview:self.noContentView aboveSubview:self.tableView];
        [self.noContentView setNeedsLayout];

    } else if (self.noContentView) {
            [self.noContentView removeFromSuperview];
    }
}

- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (self.view && [self.navigationController.topViewController isEqual:self] &&
        ![[UIApplication sharedApplication] isIdleTimerDisabled] &&
        ![self.tabBarController presentedViewController]) {
        [self reload];
    }
}

- (BOOL)autoLaunchNewFeatures
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *versionString = [info objectForKey:@"CFBundleShortVersionString"];
    NSString *lastVersionString = [settings objectForKey:@"lastVersion"];
    if ([lastVersionString isEqualToString:versionString]) {
        return NO;
    }
    [[NSUserDefaults standardUserDefaults] setValue:versionString forKey:@"lastVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGFloat tmp = screenWidth;
        screenWidth = screenHeight;
        screenHeight = tmp;
    }
    CGFloat widthFraction = 0.9;
    CGFloat heightFraction = 0.6;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        widthFraction = 0.7;
        heightFraction = 0.4;
    }
    UIView *popup = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth*widthFraction, screenHeight*heightFraction)];
    popup.backgroundColor = [UIColor clearColor];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(10,10, popup.bounds.size.width-20, popup.bounds.size.height-20)];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *changesFilePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"changes.%@", language]
                                                                ofType:@"html"
                                                           inDirectory:@"www"];
    if (!changesFilePath) {
        // if we don't have changes files for this user's preferred language,
        // default to english
        changesFilePath = [[NSBundle mainBundle] pathForResource:@"changes.en"
                                                          ofType:@"html"
                                                     inDirectory:@"www"];
    }
    
    // be defensive
    if (changesFilePath) {
        NSURL *url = [NSURL fileURLWithPath:changesFilePath];
        [webView loadRequest:[NSURLRequest requestWithURL:url]];
        [popup addSubview:webView];
        [alertView setContainerView:popup];
        [alertView setButtonTitles:[NSMutableArray arrayWithObjects:NSLocalizedString(@"OK",nil), nil]];
        [alertView setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
            [alertView close];
        }];
        [alertView setUseMotionEffects:true];
        [alertView show];
        [settings setObject:versionString forKey:@"lastVersion"];
        [settings synchronize];
        
        return YES;
    } else {
        return NO;
    }

}

- (void)clickedActivity:(id)sender event:(UIEvent *)event {
    CGPoint currentTouchPosition = [event.allTouches.anyObject locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    Observation *o = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // fake a selection
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    // transition to obs detail
    [self performSegueWithIdentifier:@"obsDetailV2" sender:o];
    return;
}

- (void)showError:(NSString *)errorMessage{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

- (void)viewActivity:(UIButton *)sender {
	
	UITableViewCell *cell = (UITableViewCell *)sender.superview.superview;
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Observation *observation = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	ObservationActivityViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL]
											 instantiateViewControllerWithIdentifier:@"ObservationActivityViewController"];
	vc.observation = observation;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // skip reload animation
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // skip reload animation
    [self.tableView reloadData];
    
    // now is a good time to check that we're displaying up to date sync info
    [self updateSyncBadge];
    
    // now is also a good time to reload the header
    [self configureHeaderForLoggedInUser];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    // skip reload animation
}


# pragma mark TableViewController methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    Observation *o = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];

    if (o.validationErrorMsg && o.validationErrorMsg > 0 && ![appDelegate.loginController.uploadManager currentUploadWorkContainsObservation:o]) {
        // only show validation error status if this obs has a validation error, and it's not being retried
        ObservationViewErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationErrorCell"];
        [self configureErrorCell:cell forIndexPath:indexPath];
        return cell;
    } else if (o.needsUpload) {
        if (appDelegate.loginController.uploadManager.isUploading && [appDelegate.loginController.uploadManager.currentlyUploadingObservation isEqual:o]) {
            // actively uploading this observation
            ObservationViewUploadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationUploadingCell"];
            [self configureUploadingCell:cell forIndexPath:indexPath];
            return cell;
        } else {
            // waiting upload, not actively uploading this observation
            ObservationViewWaitingUploadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationWaitingUploadCell"];
            [self configureWaitingUploadCell:cell forIndexPath:indexPath];
            return cell;
        }
    } else {
        ObservationViewNormalCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationNormalCell"];
        [self configureNormalCell:cell forIndexPath:indexPath];
        return cell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 100.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:INatUsernamePrefKey];
    if (username && ![username isEqualToString:@""]) {
        if (!self.meHeader) {
            self.meHeader = [[MeHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100.0f)];
        }
        
        [self.meHeader.iconButton addTarget:self
                                     action:@selector(sync:)
                           forControlEvents:UIControlEventTouchUpInside];

        [self configureHeaderForLoggedInUser];

        return self.meHeader;
        
    } else {
        AnonHeaderView *header = [[AnonHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100.0f)];
        header.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        [header.signupButton bk_addEventHandler:^(id sender) {
            
            [[Analytics sharedClient] event:kAnalyticsEventNavigateSignup
                             withProperties:@{ @"from": @"AnonMeHeader" }];
            
            [self presentSignupSplashWithReason:nil];
            
        } forControlEvents:UIControlEventTouchUpInside];
        
        [header.loginButton bk_addEventHandler:^(id sender) {
            
            [[Analytics sharedClient] event:kAnalyticsEventNavigateLogin
                             withProperties:@{ @"from": @"AnonMeHeader" }];
            
            LoginViewController *login = [[LoginViewController alloc] initWithNibName:nil bundle:nil];
            login.cancellable = YES;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
            nav.delegate = (NatusferaAppDelegate *)[UIApplication sharedApplication].delegate;
            [self presentViewController:nav animated:YES completion:nil];

        } forControlEvents:UIControlEventTouchUpInside];
        
        return header;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    Observation *o = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([appDelegate.loginController.uploadManager isUploading] && o.needsUpload) {
        return;
    } else {
        [self performSegueWithIdentifier:@"obsDetailV2" sender:o];
    }
}

#pragma mark - TableViewCell helpers

- (void)configureObservationCell:(ObservationViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    Observation *o = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // configure the photo
    if (o.sortedObservationPhotos.count > 0) {
        ObservationPhoto *op = [o.sortedObservationPhotos objectAtIndex:0];
        if (op.photoKey == nil) {
            [cell.observationImage sd_setImageWithURL:[NSURL URLWithString:op.squareURL]];
        } else {
            cell.observationImage.image = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSquareSize];
            
            // if we can't find a square image...
            if (!cell.observationImage.image) {
                // ...try again a few times, it's probably a new image in the process of being cut-down
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if ([[self.tableView indexPathsForVisibleRows] containsObject:indexPath]) {
                        [self.tableView beginUpdates];
                        [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
                        [self.tableView endUpdates];
                    }
                });
            }
        }
    } else {
        cell.observationImage.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:o.iconicTaxonName];
    }
    
    // configure the title
    if (o.speciesGuess && o.speciesGuess.length > 0) {
        [cell.titleLabel setText:o.speciesGuess];
    } else if (o.inatDescription && o.inatDescription.length > 0) {
        [cell.titleLabel setText:o.inatDescription];
    } else {
        [cell.titleLabel setText:NSLocalizedString(@"Unknown", @"unknown taxon")];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
}

- (void)configureErrorCell:(ObservationViewErrorCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [self configureObservationCell:cell forIndexPath:indexPath];
    
    Observation *o = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.dateLabel.text = [[YLMoment momentWithDate:o.observedOn] fromNowWithSuffix:NO];
    cell.subtitleLabel.text = NSLocalizedString(@"Needs Your Attention", @"subtitle for an observation that failed validation.");
}

- (void)configureUploadingCell:(ObservationViewUploadingCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [self configureObservationCell:cell forIndexPath:indexPath];
    
    cell.subtitleLabel.text = NSLocalizedString(@"Uploading...", @"subtitle for observation while it's uploading.");
    
    Observation *o = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (o.uuid) {
        float progress = [self.uploadProgress[o.uuid] floatValue];
        [cell.progressView setProgress:progress];
    }
    
    cell.dateLabel.text = [[YLMoment momentWithDate:o.observedOn] fromNowWithSuffix:NO];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)configureWaitingUploadCell:(ObservationViewWaitingUploadCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [self configureObservationCell:cell forIndexPath:indexPath];
    
    cell.subtitleLabel.text = NSLocalizedString(@"Waiting to upload...", @"Subtitle for observation when waiting to upload.");
    [cell.uploadButton addTarget:self
                          action:@selector(uploadOneObservation:)
                forControlEvents:UIControlEventTouchUpInside];
    
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loginController.uploadManager.isUploading) {
        // waiting upload, with uploads happening
        cell.uploadButton.enabled = NO;
        cell.backgroundColor = [UIColor colorWithHex:0xeaeaea];
        cell.titleLabel.textColor = [UIColor colorWithHex:0x969696];
        cell.subtitleLabel.textColor = [UIColor colorWithHex:0x969696];
        cell.observationImage.alpha = 0.5f;
    } else {
        // waiting upload, with uploads not happening
        cell.uploadButton.enabled = YES;
        cell.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.2f];
        cell.subtitleLabel.textColor = [UIColor colorWithHex:0x787878];
        cell.titleLabel.textColor = [UIColor blackColor];
        cell.observationImage.alpha = 1.0f;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)configureNormalCell:(ObservationViewNormalCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [self configureObservationCell:cell forIndexPath:indexPath];
    
    Observation *o = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (o.placeGuess && o.placeGuess.length > 0) {
        cell.subtitleLabel.text = o.placeGuess;
    } else if (o.latitude) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@, %@", o.latitude, o.longitude];
    } else {
        cell.subtitleLabel.text = NSLocalizedString(@"Somewhere...",nil);
    }
    
    if (o.hasUnviewedActivity.boolValue) {
        [cell.activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat-red"] forState:UIControlStateNormal];
    } else {
        [cell.activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat"] forState:UIControlStateNormal];
    }
    
    [cell.activityButton setTitle:[NSString stringWithFormat:@"%ld", (long)o.activityCount] forState:UIControlStateNormal];
    
    if (o.activityCount > 0) {
        cell.activityButton.hidden = NO;
        cell.interactiveActivityButton.hidden = NO;
    } else {
        cell.activityButton.hidden = YES;
        cell.interactiveActivityButton.hidden = YES;
    }
    
    [cell.interactiveActivityButton addTarget:self
                                       action:@selector(clickedActivity:event:)
                             forControlEvents:UIControlEventTouchUpInside];
    
    if (o.timeObservedAt != nil) {
        cell.dateLabel.text = [[YLMoment momentWithDate:o.timeObservedAt] fromNowWithSuffix:NO];
    }
    else {
        cell.dateLabel.text = [[YLMoment momentWithDate:o.observedOn] fromNowWithSuffix:NO];
    }
}


#pragma mark - Header helpers

- (void)configureHeaderForLoggedInUser {
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:INatUsernamePrefKey];
    if (username && username.length > 0) {
        NSFetchRequest *meFetch = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        meFetch.predicate = [NSPredicate predicateWithFormat:@"login == %@", username];
        NSError *fetchError;
        User *me = [[[User managedObjectContext] executeFetchRequest:meFetch error:&fetchError] firstObject];
        if (fetchError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching: %@",
                                                fetchError.localizedDescription]];
            
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fetch Error", nil)
                                        message:fetchError.localizedDescription
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }
        
        if (me) {
            [self configureHeaderView:self.meHeader forUser:me];
        }
    }
}

- (void)configureHeaderForActiveUploading:(MeHeaderView *)view {
    [view.iconButton sd_cancelImageLoadForState:UIControlStateNormal];
    [view.iconButton setImage:nil forState:UIControlStateNormal];
    [view.iconButton setTintColor:[UIColor whiteColor]];
    view.iconButton.backgroundColor = [UIColor inatTint];

    // allow cancel
    FAKIcon *stopIcon = [FAKIonIcons iosCloseOutlineIconWithSize:50];
    [view.iconButton setAttributedTitle:stopIcon.attributedString
                               forState:UIControlStateNormal];
    view.iconButton.enabled = YES;
    
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploadManager = appDelegate.loginController.uploadManager;
    if (uploadManager.isSyncingDeletes) {
        self.meHeader.obsCountLabel.text = NSLocalizedString(@"Syncing...", @"Title of me header when syncing deletions.");
    } else {
        NSInteger current = uploadManager.indexOfCurrentlyUploadingObservation + 1;
        NSInteger total = uploadManager.currentUploadSessionTotalObservations;
        if (total > 1) {
            NSString *baseUploadingStatusStr  = NSLocalizedString(@"Uploading %d of %d",
                                                                  @"Title of me header while uploading observations. First number is the index of the obs being uploaded, second is the count in the current upload 'session'.");
            self.meHeader.obsCountLabel.text = [NSString stringWithFormat:baseUploadingStatusStr, current, total];
        } else {
            NSString *baseUploadingStatusStr = NSLocalizedString(@"Uploading '%@'", @"Title of me header while uploading one observation. Text is observation species.");
            NSString *speciesName = NSLocalizedString(@"Unknown", @"unknown taxon");
            if (uploadManager.currentlyUploadingObservation.speciesGuess) {
                speciesName = uploadManager.currentlyUploadingObservation.speciesGuess;
            } else if (uploadManager.currentlyUploadingObservation.inatDescription) {
                speciesName = uploadManager.currentlyUploadingObservation.inatDescription;
            }
            self.meHeader.obsCountLabel.text = [NSString stringWithFormat:baseUploadingStatusStr, speciesName];
        }
    }
    
    [view startAnimatingUpload];
}

- (void)configureHeaderView:(MeHeaderView *)view forUser:(User *)user {
    NSUInteger needingUploadCount = [[Observation needingUpload] count];
    NSUInteger needingDeleteCount = [Observation deletedRecordCount] + [ObservationPhoto deletedRecordCount] + [ProjectObservation deletedRecordCount] + [ObservationFieldValue deletedRecordCount];
    
    if (needingUploadCount > 0 || needingDeleteCount > 0) {

        NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
        UploadManager *uploadManager = appDelegate.loginController.uploadManager;
        
        if (uploadManager.isUploading) {
            [self configureHeaderForActiveUploading:view];
        } else {
            
            // cancel any existing upload animations
            [view stopAnimatingUpload];
            
            NSString *uploadButtonTitleText = NSLocalizedString(@"Upload", @"Title for upload button.");
            
            FAKIcon *uploadIcon = [FAKIonIcons iosCloudUploadIconWithSize:46];
            NSMutableAttributedString *uploadIconString = [[NSMutableAttributedString alloc] initWithAttributedString:uploadIcon.attributedString];
            // explicit linebreak because uilabel doesn't seem to be able to calculate number of lines required with a FAK glyph
            NSString *uploadButtonSecondLine = [NSString stringWithFormat:@"\n%@", uploadButtonTitleText];
            [uploadIconString appendAttributedString:[[NSAttributedString alloc] initWithString:uploadButtonSecondLine
                                                                                     attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:11] }]];
            
            // set a max line height on the "Upload" text line. required because the first line of the label is a 50pt glyph
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 0;
            paragraphStyle.maximumLineHeight = 11;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            [uploadIconString addAttribute:NSParagraphStyleAttributeName
                                     value:paragraphStyle
                                     range:NSMakeRange(2, uploadIconString.length - 2)];
            
            // image seems to override title text, so clear it
            [view.iconButton sd_cancelImageLoadForState:UIControlStateNormal];
            [view.iconButton setImage:nil forState:UIControlStateNormal];
            
            view.iconButton.backgroundColor = [UIColor inatTint];
            view.iconButton.tintColor = [UIColor whiteColor];
            [view.iconButton setAttributedTitle:uploadIconString
                                       forState:UIControlStateNormal];
            
            // the upload icon is one line of attributed text
            view.iconButton.titleLabel.numberOfLines = 2;
            view.iconButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            
            // allow interaction with the upload button
            view.iconButton.enabled = YES;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // only animate the upload button if it's still an upload button
                NSString *uploadButtonCurrentTitle = [[view.iconButton attributedTitleForState:UIControlStateNormal] string];
                if (!uploadButtonCurrentTitle || [uploadButtonCurrentTitle rangeOfString:uploadButtonTitleText].location == NSNotFound) {
                    return;
                }
                
                [UIView animateWithDuration:0.2f
                                 animations:^{
                                     view.iconButton.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                                 } completion:^(BOOL finished) {
                                     [UIView animateWithDuration:0.2f
                                                      animations:^{
                                                          view.iconButton.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
                                                      } completion:^(BOOL finished) {
                                                          [UIView animateWithDuration:0.2f
                                                                           animations:^{
                                                                               view.iconButton.transform = CGAffineTransformIdentity;
                                                                           }];
                                                      }];
                                 }];
            });
            
            if (needingUploadCount > 0) {
                NSString *baseUploadCountStr;
                if (needingUploadCount == 1) {
                    baseUploadCountStr = NSLocalizedString(@"%d Observation To Upload",
                                                           @"Count of observations to upload, singular.");
                } else {
                    baseUploadCountStr = NSLocalizedString(@"%d Observations To Upload",
                                                           @"Count of observations to upload, plural.");
                }
                view.obsCountLabel.text = [NSString stringWithFormat:baseUploadCountStr, needingUploadCount];
            } else if (needingDeleteCount > 0) {
                view.obsCountLabel.text = NSLocalizedString(@"Deletes To Sync",
                                                            @"Deletes pending sync.");
            }
        }
        
        
        
    } else {
        [view.iconButton setAttributedTitle:nil forState:UIControlStateNormal];
        view.iconButton.backgroundColor = [UIColor clearColor];
        view.iconButton.enabled = NO;
        
        // icon
        if (user.mediumUserIconURL && ![user.mediumUserIconURL isEqualToString:@""]) {
            // render the user icon as an image, not a mask,
            // which sdwebimage doesn't seem to be able to do directly
            [view.iconButton sd_setImageWithURL:[NSURL URLWithString:user.mediumUserIconURL]
                                       forState:UIControlStateNormal
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                          [view.iconButton setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                           forState:UIControlStateNormal];
                                      }];
        } else if (user.userIconURL && ![user.userIconURL isEqualToString:@""]) {
            // render the user icon as an image, not a mask,
            // which sdwebimage doesn't seem to be able to do directly
            [view.iconButton sd_setImageWithURL:[NSURL URLWithString:user.userIconURL]
                                       forState:UIControlStateNormal
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                          [view.iconButton setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                           forState:UIControlStateNormal];
                                      }];
        } else {
            FAKIcon *person = [FAKIonIcons iosPersonIconWithSize:80.0f];
            [person addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [view.iconButton setImage:[[person imageWithSize:CGSizeMake(80, 80)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                             forState:UIControlStateNormal];
        }
        
        // observation count
        if (user.observationsCount.integerValue > 0) {
            NSString *baseObsCountStr;
            if (user.observationsCount.integerValue == 1) {
                baseObsCountStr = NSLocalizedString(@"%d Observation", @"Count of observations by this user, singular.");
            } else {
                baseObsCountStr = NSLocalizedString(@"%d Observations", @"Count of observations by this user, plural.");
            }
            view.obsCountLabel.text = [NSString stringWithFormat:baseObsCountStr, user.observationsCount.integerValue];
        } else {
            view.obsCountLabel.text = NSLocalizedString(@"No Observations", @"Header observation count title when there are none.");
        }
    }
}

- (void)loadUserForHeader {
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:INatUsernamePrefKey];
    if (username) {
        
        self.navigationItem.title = username;
        
        if ([[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined] && [[RKClient sharedClient]  isNetworkReachable]) {
            
            NSString *path = [NSString stringWithFormat:@"/people/%@.json", username];
            
            [[Analytics sharedClient] debugLog:@"Network - Load me for header"];
            [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                            usingBlock:^(RKObjectLoader *loader) {
                                                                loader.objectMapping = [User mapping];
                                                                loader.delegate = self;
                                                            }];
        }
    } else {
        self.navigationItem.title = NSLocalizedString(@"Me", @"Placeholder text for not logged title on me tab.");
    }
}

# pragma mark memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - NSNotificationCenter

- (void)userSignedIn {
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Fetch Error: %@", error.localizedDescription]];
    }
    [self refreshRequestedNotify:YES];
}

- (void)coreDataRebuilt {
    self.lastRefreshAt = [NSDate distantPast];
    [self.noContentView removeFromSuperview];
    self.noContentView = nil;
    
    // rebuild the fetched results controller
    _fetchedResultsController = nil;
    
    // reload the tableview
    [self.tableView reloadData];
    [self loadUserForHeader];
}

#pragma mark - Fetched Results Controller helper

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (!_fetchedResultsController) {
        // NSFetchedResultsController request for my observations
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Observation"];
        
        // sort by common name, if available
        request.sortDescriptors = @[
                                    [[NSSortDescriptor alloc] initWithKey:@"sortable" ascending:NO],
                                    [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:NO],
                                    ];
        
        // no request predicate yet, all Observations in core data are "mine"
        
        // setup our fetched results controller
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:[NSManagedObjectContext defaultContext]
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        // update our tableview based on changes in the fetched results
        _fetchedResultsController.delegate = self;
    }
    
    return _fetchedResultsController;
}

#pragma mark - View lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.navigationController.tabBarItem.image = ({
            FAKIcon *meOutline = [FAKIonIcons iosPersonOutlineIconWithSize:35];
            [meOutline addAttribute:NSForegroundColorAttributeName value:[UIColor inatInactiveGreyTint]];
            [[meOutline imageWithSize:CGSizeMake(25, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.navigationController.tabBarItem.selectedImage = ({
            FAKIcon *meFilled = [FAKIonIcons iosPersonIconWithSize:35];
            [meFilled addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [meFilled imageWithSize:CGSizeMake(25, 45)];
        });

        self.navigationController.tabBarItem.title = NSLocalizedString(@"Me", nil);
        
        self.uploadProgress = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

// if you need to test syncing lots of obs with the fetched results controller, do:
//    [Observation deleteAll];
//    for (int i = 0; i < 50; i++) {
//        [Observation object];
//    }
//    NSError *error;
//    [[[RKObjectManager sharedManager] objectStore] save:&error];
//    if (error) {
//        NSLog(@"ALERT: %@", error.localizedDescription);
//    }
    
    static NSString *FirstSignInKey = @"firstSignInSeen";
    static NSString *SeenV262Key = @"seenVersion262";
    
    // re-using 'firstSignInSeen' BOOL, which used to be set during the initial launch
    // when the user saw the login prompt for the first time.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:FirstSignInKey]) {
        // completely new users default to autocomplete on
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kINatAutocompleteNamesPrefKey];
        
        // completely new users default to autoupload on
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kInatAutouploadPrefKey];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:FirstSignInKey];
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:SeenV262Key];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // new settings as of 2.6.2, for existing users
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SeenV262Key]) {
        // existing users default to autoupload off
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:kInatAutouploadPrefKey];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:SeenV262Key];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self presentAutouploadAlert];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userSignedIn)
                                                 name:kUserLoggedInNotificationName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(coreDataRebuilt)
                                                 name:kInatCoreDataRebuiltNotification
                                               object:nil];
    
    
    // perform the iniital local fetch
    NSError *fetchError;
    [self.fetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"fetch error: %@",
                                            fetchError.localizedDescription]];

        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fetch Error", nil)
                                    message:fetchError.localizedDescription
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
    
    self.navigationItem.leftBarButtonItem = nil;
    FAKIcon *settings = [FAKIonIcons iosGearOutlineIconWithSize:30];
    UIImage *settingsImage = [settings imageWithSize:CGSizeMake(30, 30)];
    settings.iconFontSize = 20;
    UIImage *settingsLandscapeImage = [settings imageWithSize:CGSizeMake(20, 20)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImage
                                                                landscapeImagePhone:settingsLandscapeImage
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(settings)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:) 
                                                 name:NSManagedObjectContextDidSaveNotification 
                                               object:[Observation managedObjectContext]];
    
    
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController.uploadManager setDelegate:self];
}

- (void)settings {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *vc = [storyBoard instantiateViewControllerWithIdentifier:@"Settings"];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
    
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
    if (username.length) {
        RefreshControl *refresh = [[RefreshControl alloc] init];
        refresh.backgroundColor = [UIColor inatDarkGray];
        refresh.tintColor = [UIColor whiteColor];
        refresh.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Pull to Refresh", nil)
                                                                  attributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] }];
		[refresh addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
		self.refreshControl = refresh;
	} else {
		self.refreshControl = nil;
	}
    
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateSyncBadge];
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    [self.tableView reloadData];
    [self checkEmpty];

    // automatically sync if there's network and we haven't synced in the last hour
    CGFloat minutes = 60,
    seconds = minutes * 60;
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
    if (username.length &&
        [[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined] &&
        [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable] &&
        (!self.lastRefreshAt || [self.lastRefreshAt timeIntervalSinceNow] < -1*seconds)) {
        [self refreshRequestedNotify:NO];
        [self checkForDeleted];
        [self checkNewActivity];
    }
    

    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateObservations];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];    
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateObservations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"observationDetail"]) {
        ObservationDetailViewController *ovc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
        ObservationPageViewController *pvc = [segue destinationViewController];
        [ovc setDelegate:self];
        Observation *o = (Observation *)sender;
        [ovc setObservation:o];
        [pvc setViewControllers:[NSArray arrayWithObject:ovc]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:nil];
    } else if ([segue.identifier isEqualToString:@"obsDetailV2"]) {
        ObsDetailV2ViewController *ovc = [segue destinationViewController];
        ovc.observation = (Observation *)sender;
    }
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    if ([objectLoader.URL.absoluteString rangeOfString:@"/people/"].location != NSNotFound) {
        // got me object
        
        NSError *saveError;
        [[[RKObjectManager sharedManager] objectStore] save:&saveError];
        if (saveError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"save error: %@",
                                                saveError.localizedDescription]];
            
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save Error", nil)
                                        message:saveError.localizedDescription
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }
        
        // triggers reconfiguration of the header
        [self.tableView reloadData];

        return;
    }
    
	[self.refreshControl endRefreshing];
    if (objects.count == 0) {
        [self checkEmpty];
        return;
    }
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
		if ([o isKindOfClass:[Observation class]]) {
			Observation *observation = (Observation *)o;
            DeletedRecord *dr = [DeletedRecord objectWithPredicate:[NSPredicate predicateWithFormat:@"modelName == 'Observation' AND recordID = %@", o.recordID]];
            if (dr) {
                [o destroy];
                continue;
            }
			if (observation.localUpdatedAt == nil || !observation.needsSync) { // this only occurs for downloaded items, not locally updated items
				[observation setSyncedAt:now];
			}
			NSArray *sortedObservationPhotos = observation.sortedObservationPhotos;
			for (ObservationPhoto *photo in sortedObservationPhotos) {
				if (photo.localUpdatedAt == nil || !photo.needsSync) { // this only occurs for downloaded items, not locally updated items
					[photo setSyncedAt:now];
				}
			}
            for (ObservationFieldValue *ofv in observation.observationFieldValues) {
                if (ofv.needsSync) {
                    [[INatModel managedObjectContext] refreshObject:ofv mergeChanges:NO];
                } else {
                    ofv.syncedAt = now;
                }
			}
		}
        
        // don't update records that need to be synced
        if (o.needsSync) {
            [[INatModel managedObjectContext] refreshObject:o mergeChanges:NO];
        }
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
	
	// check for new activity
	[self checkNewActivity];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {

    if ([objectLoader.URL.absoluteString rangeOfString:@"/people/"].location != NSNotFound) {
        // was running into a bug in release build config where the object loader was
        // getting deallocated after handling an error.  This is a kludge.
        self.meObjectLoader = objectLoader;

        // silently do nothing
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"load Me error: %@",
                                            error.localizedDescription]];

        return;
    }
	
    NSString *errorMsg;
    bool jsonParsingError = false, authFailure = false;
    switch (objectLoader.response.statusCode) {
        // UNPROCESSABLE ENTITY
        case 422:
            errorMsg = NSLocalizedString(@"Unprocessable entity",nil);
            break;
            
        default:
            // KLUDGE!! RestKit doesn't seem to handle failed auth very well
            jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
            authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
            errorMsg = error.localizedDescription;
    }
    
    if (self.isSyncing || self.refreshControl.isRefreshing) {
        NSString *msg, *title;
        if (error.code == -1004 || ([error.domain isEqualToString:@"org.restkit.RestKit.ErrorDomain"] && error.code == 2)) {
            title = NSLocalizedString(@"Internet connection required", nil);
            msg = NSLocalizedString(@"You must be connected to the Internet to do this.", nil);
        } else {
            title = NSLocalizedString(@"Whoops!",nil);
            msg = [NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg];
        }
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
                                                     message:msg
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
    [self.refreshControl endRefreshing];
}

#pragma mark - RKRequestDelegate

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
	if (response.allHeaderFields[@"X-Deleted-Observations"]) {
		NSString *deletedString = response.allHeaderFields[@"X-Deleted-Observations"];
		NSArray *recordIDs = [deletedString componentsSeparatedByString:@","];
		NSArray *records = [Observation matchingRecordIDs:recordIDs];
		for (INatModel *record in records) {
			[record destroy];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:INatLastDeletedSync];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	if ([request.resourcePath rangeOfString:@"new_updates.json"].location != NSNotFound && (response.statusCode == 200 || response.statusCode == 304)) {
		NSString *jsonString = [[NSString alloc] initWithData:response.body
                                                     encoding:NSUTF8StringEncoding];
        NSError* error = nil;
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
        id parsedData = [parser objectFromString:jsonString error:&error];
		NSDate *now = [NSDate date];
		if (parsedData && [parsedData isKindOfClass:[NSDictionary class]] && !error) {
			NSNumber *recordID = ((NSDictionary *)parsedData)[@"id"];
			Observation *observation = [Observation objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID == %@", recordID]];
			observation.hasUnviewedActivity = [NSNumber numberWithBool:YES];
            observation.syncedAt = now;
			[[[RKObjectManager sharedManager] objectStore] save:&error];
		} else if (parsedData && [parsedData isKindOfClass:[NSArray class]] && !error) {
			for (NSDictionary *notification in (NSArray *)parsedData) {
				NSNumber *recordID = notification[@"resource_id"];
				Observation *observation = [Observation objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID == %@", recordID]];
				observation.hasUnviewedActivity = [NSNumber numberWithBool:YES];
                observation.syncedAt = now;
			}
			[[[RKObjectManager sharedManager] objectStore] save:&error];
		}
	} else {
		NSLog(@"Received status code %ld for %@", (long)response.statusCode, request.resourcePath);
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
	NSLog(@"Request Error: %@", error.localizedDescription);
}

#pragma mark - Upload Notification Delegate

- (void)uploadManagerUploadSessionAuthRequired:(UploadManager *)uploadManager {

    [self syncStopped];
    
    [[Analytics sharedClient] debugLog:@"Upload - Auth Required"];
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                                      @"Via": @"Auth Required",
                                      }];
    
    NSString *reasonMsg = NSLocalizedString(@"You must be logged in to upload to Natusfera.gbif.es.",
                                            @"This is an explanation for why the sync button triggers a login prompt.");
    [self presentSignupSplashWithReason:reasonMsg];
}

- (void)uploadManagerUploadSessionFinished:(UploadManager *)uploadManager {
    // allow any pending upload animations to finish
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // make sure any deleted records get gone
        NSError *error = nil;
        [[[RKObjectManager sharedManager] objectStore] save:&error];
        
        [self syncStopped];
        
        // reload the Me user from the server
        [self loadUserForHeader];
    });

    [[Analytics sharedClient] debugLog:@"Upload - Session Finished"];
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                                      @"Via": @"Upload Complete",
                                      }];
}

- (void)uploadManager:(UploadManager *)uploadManager cancelledFor:(INatModel *)object {
    [[Analytics sharedClient] debugLog:@"Upload - Upload Cancelled"];

    self.meHeader.obsCountLabel.text = NSLocalizedString(@"Cancelling...", @"Title of me header while cancellling an upload session.");
    [self syncStopped];
}

- (void)uploadManager:(UploadManager *)uploadManager uploadStartedFor:(Observation *)observation number:(NSInteger)current of:(NSInteger)total {
    [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Upload - Started %ld of %ld uploads", (long)current, (long)total]];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    if (observation.uuid) {
        self.uploadProgress[observation.uuid] = @(0);
    }

    [self configureHeaderForLoggedInUser];
    [self.meHeader startAnimatingUpload];
    
    NSIndexPath *ip = [self.fetchedResultsController indexPathForObject:observation];
    if (ip) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (void)uploadManager:(UploadManager *)uploadManager uploadSuccessFor:(Observation *)observation {
    [[Analytics sharedClient] debugLog:@"Upload - Success"];

    [self configureHeaderForLoggedInUser];
    [self updateSyncBadge];

    NSIndexPath *ip = [self.fetchedResultsController indexPathForObject:observation];
    if (ip) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}


- (void)uploadManager:(UploadManager *)uploadManager uploadProgress:(float)progress for:(Observation *)observation {
    [[Analytics sharedClient] debugLog:@"Upload - Progress"];
    
    if (observation.uuid) {
        self.uploadProgress[observation.uuid] = @(progress);
    }
    
    NSIndexPath *ip = [self.fetchedResultsController indexPathForObject:observation];
    if (ip) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                              withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

- (void)uploadManager:(UploadManager *)uploadManager nonFatalErrorForObservation:(Observation *)observation {
    [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Upload - Non-Fatal Error for %@", observation]];
    
    NSIndexPath *ip = [self.fetchedResultsController indexPathForObject:observation];
    if (ip) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (void)uploadManager:(UploadManager *)uploadManager uploadFailedFor:(INatModel *)object error:(NSError *)error {
    [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Upload - Fatal Error %@", error.localizedDescription]];
    
    // stop uploading
    [self syncStopped];
    
    NSString *alertTitle = NSLocalizedString(@"Whoops!", @"Default upload failure alert title.");
    NSString *alertMessage;
    
    if (error) {
        if (error.domain == RKErrorDomain && error.code == RKRequestConnectionTimeoutError) {
            alertTitle = NSLocalizedString(@"Request timed out",nil);
            alertMessage = NSLocalizedString(@"This can happen when your Internet connection is slow or intermittent.  Please try again the next time you're on WiFi.",nil);
        } else {
            alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), error.localizedDescription];
        }
    } else {
        alertMessage = NSLocalizedString(@"There was an unexpected error.",
                                         @"Unresolvable and unknown error during observation upload.");
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncFailed
                     withProperties:@{
                                      @"Alert": alertMessage,
                                      }];
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:alertTitle
                                                 message:alertMessage
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                       otherButtonTitles:nil];
    [av show];
}

- (void)uploadManager:(UploadManager *)uploadManager deleteStartedFor:(DeletedRecord *)deletedRecord {
    [[Analytics sharedClient] debugLog:@"Upload - Delete Started"];

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [self configureHeaderForLoggedInUser];
    [self.meHeader startAnimatingUpload];
}

- (void)uploadManager:(UploadManager *)uploadManager deleteSuccessFor:(DeletedRecord *)deletedRecord {
    [[Analytics sharedClient] debugLog:@"Upload - Delete Success"];

    [self updateSyncBadge];
}

- (void)uploadManagerDeleteSessionFinished:(UploadManager *)uploadManager {
    [[Analytics sharedClient] debugLog:@"Upload - Delete Session Finished"];

    [self syncStopped];
}

- (void)uploadManager:(UploadManager *)uploadManager deleteFailedFor:(DeletedRecord *)deletedRecord error:(NSError *)error {
    [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Upload - Delete Failed: %@", [error localizedDescription]]];

    [self syncStopped];
    
    NSString *alertTitle = NSLocalizedString(@"Deleted Failed", @"Delete failed message");
    NSString *alertMsg;
    if (error) {
        alertMsg = error.localizedDescription;
    } else {
        alertMsg = NSLocalizedString(@"Unknown error while attempting to delete.", @"unknown delete error");
    }
    
    [[[UIAlertView alloc] initWithTitle:alertTitle
                                message:alertMsg
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
}

@end
