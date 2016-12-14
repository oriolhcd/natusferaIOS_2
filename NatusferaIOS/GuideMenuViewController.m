//
//  GuideMenuViewController.m
//  Natusfera
//
//  Created by Ken-ichi Ueda on 9/19/13.
//  Copyright (c) 2013 Natusfera. All rights reserved.
//

#import "GuideMenuViewController.h"
#import "GuideViewController.h"
#import "Observation.h"
#import "SSZipArchive.h"
#import "UIColor+Natusfera.h"
#import "Analytics.h"

@implementation GuideMenuViewController

@synthesize guide = _guide;
@synthesize delegate = _delegate;
@synthesize tagPredicates = _tagNames;
@synthesize tagsByPredicate = _tagsByPredicate;
@synthesize tagCounts = _tagCounts;

@synthesize ngzDownloadConnection = _ngzDownloadConnection;
@synthesize lastStatusCode = _lastStatusCode;
@synthesize progress = _progress;
@synthesize expectedBytes = _expectedBytes;
@synthesize receivedData = _receivedData;
@synthesize ngzFilePath = _ngzFilePath;




static int TextCellTextViewTag = 101;
static int ConfirmDownloadAlertViewTag = 100;
static int ProgressViewTag = 102;
static int ProgressLabelTag = 103;
static int AboutSection = 1;
static int DownloadRow = 2;
static int DetailCellTextTag = 10;
static int DetailCellDetailTag = 11;
static NSString *RightDetailCellIdentifier = @"RightDetailCell";
static CGSize maximumSize;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.delegate && !self.guide) {
        self.guide = self.delegate.guideMenuControllerGuide;
        if (!self.tagsByPredicate) {
            self.tagsByPredicate = [[NSMutableDictionary alloc] init];
        }
        if (!self.tagCounts) {
            self.tagCounts = [[NSMutableDictionary alloc] init];
        }
        NSMutableDictionary *tagsByPredicate = [[NSMutableDictionary alloc] init];
        NSMutableSet *predicates = [[NSMutableSet alloc] init];
        [self.guide iterateWithRootXPath:@"//GuideTaxon/tag" usingBlock:^(RXMLElement *tag) {
            NSString *predicate = [tag attribute:@"predicate"];
            if (!predicate || predicate.length == 0) {
                predicate = NSLocalizedString(@"TAGS", nil);
            }
            NSString *value = [tag text];
            NSMutableSet *tags = [tagsByPredicate objectForKey:predicate];
            [predicates addObject:predicate];
            if (tags) {
                [tags addObject:value];
            } else {
                tags = [[NSMutableSet alloc] initWithObjects:value, nil];
                [tagsByPredicate setValue:tags forKey:predicate];
            }
            NSNumber *count = [self.tagCounts objectForKey:tag.text];
            if (!count) {
                count = [NSNumber numberWithInt:0];
            }
            [self.tagCounts setValue:[NSNumber numberWithInt:1+count.intValue] forKey:[tag text]];
        }];
        for (NSString *predicate in tagsByPredicate) {
            NSSet *ptags = [tagsByPredicate objectForKey:predicate];
            [self.tagsByPredicate setValue:[[ptags allObjects] sortedArrayUsingSelector:@selector(compare:)]
                                    forKey:predicate];
        }
        if (!self.tagPredicates) {
            self.tagPredicates = [[NSMutableArray alloc] init];
        }
        self.tagPredicates = [[predicates allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateGuideMenu];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateGuideMenu];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)tagsForTagName:(NSString *)tagName
{
    return [self.tagsByPredicate objectForKey:tagName];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return
        self.tagPredicates.count + // tags
        1 + // description
        1 + // about
        0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < self.tagPredicates.count) {
        NSArray *tags = [self.tagsByPredicate objectForKey:[self.tagPredicates objectAtIndex:section]];
        return tags.count;
    } else {
        NSInteger i = section - self.tagPredicates.count;
        // Description
        if (i == 0) {
            return 1;
        }
        // About
        else {
            return 3;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    static NSString *TextCellIdentifier = @"TextCell";
    static NSString *SubtitleCellIdentifier = @"SubtitleCell";
    static NSString *ProgressCellIdentifier = @"ProgressCell";
    NSString *tag = [self tagForIndexPath:indexPath];
    if (tag) {
        cell = [self cellForTag:tag atIndexPath:indexPath];
    } else {
        NSInteger i = indexPath.section - self.tagPredicates.count;
        if (i == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:TextCellIdentifier forIndexPath:indexPath];
            UITextView *textView = (UITextView *)[cell viewWithTag:TextCellTextViewTag];
            textView.text = [self.guide.desc stringByStrippingHTML];
            textView.textAlignment = NSTextAlignmentNatural;
        } else {
            if (indexPath.row < 2) {
                cell = [tableView dequeueReusableCellWithIdentifier:RightDetailCellIdentifier forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.userInteractionEnabled = NO;
            }
            if (indexPath.row == 0) {
                // Adding auto layout for cell.
                [self setupConstraintsForCell:cell];
                UILabel *textLabel = (UILabel *)[cell viewWithTag:DetailCellTextTag];
                UILabel *detailTextLabel = (UILabel *)[cell viewWithTag:DetailCellDetailTag];
                textLabel.text = NSLocalizedString(@"Editor", nil);
                detailTextLabel.text = self.guide.compiler;
            } else if (indexPath.row == 1) {
                // Adding auto layout for cell.
                [self setupConstraintsForCell:cell];
                UILabel *textLabel = (UILabel *)[cell viewWithTag:DetailCellTextTag];
                UILabel *detailTextLabel = (UILabel *)[cell viewWithTag:DetailCellDetailTag];
                textLabel.text = NSLocalizedString(@"License", nil);
                detailTextLabel.text = self.guide.license;
            } else {
                if (self.isDownloading) {
                    cell = [tableView dequeueReusableCellWithIdentifier:ProgressCellIdentifier forIndexPath:indexPath];
                    self.progress = (UIProgressView *)[cell viewWithTag:ProgressViewTag];
                    UILabel *label = (UILabel *)[cell viewWithTag:ProgressLabelTag];
                    label.textAlignment = NSTextAlignmentNatural;
                    label.text = NSLocalizedString(@"Downloading...", nil);
                } else {
                    cell = [tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier forIndexPath:indexPath];
                    UILabel *title = (UILabel *)[cell viewWithTag:202];
                    title.textAlignment = NSTextAlignmentNatural;
                    UILabel *subtitle = (UILabel *)[cell viewWithTag:203];
                    subtitle.textAlignment = NSTextAlignmentNatural;
                    UIImageView *imageView = (UIImageView *)[cell viewWithTag:201];
                    if (self.guide.ngzDownloadedAt) {
                        title.textColor = [UIColor blackColor];
                        title.text = NSLocalizedString(@"Downloaded", nil);
                        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
                        [fmt setTimeZone:[NSTimeZone localTimeZone]];
                        [fmt setDateStyle:NSDateFormatterMediumStyle];
                        [fmt setTimeStyle:NSDateFormatterMediumStyle];
                        subtitle.text = [fmt stringFromDate:self.guide.ngzDownloadedAt];
                        imageView.image = [UIImage imageNamed:@"258-checkmark"];
                    } else if (self.guide.ngzURL) {
                        title.textColor = [UIColor blackColor];
                        title.text = NSLocalizedString(@"Download for offline use", nil);
                        subtitle.text = self.guide.ngzFileSize;
                        imageView.image = [UIImage imageNamed:@"265-download-gray"];
                    } else {
                        title.textColor = [UIColor darkGrayColor];
                        title.text = NSLocalizedString(@"Download not available", nil);
                        subtitle.text = NSLocalizedString(@"Guide editor must enable this feature.", nil);
                        imageView.image = [UIImage imageNamed:@"265-download-gray"];
                    }
                }
            }
        }
    }
    [cell setIndentationWidth:60.0];
    return cell;
}

- (UITableViewCell *)cellForTag:(NSString *)tag atIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:RightDetailCellIdentifier forIndexPath:indexPath];
    NSArray *pieces = [tag componentsSeparatedByString:@"="];
    // Adding auto layout for cell.
    [self setupConstraintsForCell:cell];
    UILabel *textLabel = (UILabel *)[cell viewWithTag:DetailCellTextTag];
    UILabel *detailTextLabel = (UILabel *)[cell viewWithTag:DetailCellDetailTag];
    
    if (pieces.count == 1) {
        textLabel.text = pieces[0];
    } else {
        textLabel.text = pieces[1];
    }
    textLabel.textAlignment = NSTextAlignmentNatural;
    detailTextLabel.text = [[self.tagCounts objectForKey:tag] stringValue];
//    detailTextLabel.textAlignment = NSTextAlignmentNatural;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.userInteractionEnabled = YES;
    UIView *bgv = [[UIView alloc] initWithFrame:cell.frame];
    bgv.backgroundColor = [UIColor inatTint];
    cell.selectedBackgroundView = bgv;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *tag = [self tagForIndexPath:indexPath];
    if (tag) {
        return 44.0;
    }
    NSInteger i = indexPath.section - self.tagPredicates.count;
    if (i != 0) return 44.0;
    //comentador por M.Lujano:28/06/2016
    //CGSize constraintSize = CGSizeMake(260.0f, MAXFLOAT);
    //CGSize labelSize = [self.guide.desc.stringByStrippingHTML sizeWithFont:[UIFont systemFontOfSize:15.0]
    //                                                     constrainedToSize:constraintSize
    //
    //                                                     lineBreakMode:NSLineBreakByWordWrapping];
    
    //primer intento M.Lujano:28/06/2016
    //let's make an NSAttributedString first
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: self.guide.desc.stringByStrippingHTML];
    //add LineBreakMode
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [attributedString setAttributes:@{NSParagraphStyleAttributeName:paragraphStyle}
                              range:NSMakeRange(0, attributedString.length)];
    //Add Font
    [attributedString setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0]} range:NSMakeRange(0,attributedString.length)];
    //Now let's make the Bounding Rect
    CGSize labelSize = [attributedString boundingRectWithSize:maximumSize options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    
    
       
    return labelSize.height + 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title;
    NSInteger i = section - self.tagPredicates.count;
    if (section < self.tagPredicates.count) {
        NSString *humanTitle = [[[[self.tagPredicates objectAtIndex:section] componentsSeparatedByString:@":"] lastObject] humanize];
        title = [NSLocalizedString(humanTitle, nil) uppercaseString];
    } else if (i == 0) {
        title = NSLocalizedString(@"DESCRIPTION", nil);
    } else {
        title = NSLocalizedString(@"ABOUT", nil);
    }
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    view.backgroundColor = [UIColor grayColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(68, 0, 252, 22)];
    label.textAlignment = NSTextAlignmentNatural;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.text = title;
    label.font = [UIFont systemFontOfSize:12.0];
    [view addSubview:label];
    return view;
}

- (NSString *)tagForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= self.tagPredicates.count) {
        return Nil;
    }
    NSString *predicate = [self.tagPredicates objectAtIndex:indexPath.section];
    NSArray *tags = [self.tagsByPredicate objectForKey:predicate];
    return [tags objectAtIndex:indexPath.row];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *tag = [self tagForIndexPath:indexPath];
    if (tag && self.delegate) {
        [self.delegate guideMenuControllerAddedFilterByTag:tag];
        return;
    }
    NSInteger i = indexPath.section - self.tagPredicates.count;
    if (i == AboutSection && indexPath.row == DownloadRow) {
        if (self.guide.ngzDownloadedAt) {
            UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Manage download", nil)
                                                            delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              destructiveButtonTitle:NSLocalizedString(@"Delete download", nil)
                                                   otherButtonTitles:NSLocalizedString(@"Re-download", nil), nil];
            [as showFromTabBar:self.tabBarController.tabBar];
        } else if (self.guide.ngzURL) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                                         message:[NSString stringWithFormat:NSLocalizedString(@"This will download %@ of data so you can use this guide even when you don't have Internet access.", nil), self.guide.ngzFileSize]
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                               otherButtonTitles:NSLocalizedString(@"Download",nil), nil];
            av.tag = ConfirmDownloadAlertViewTag;
            [av show];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *tag = [self tagForIndexPath:indexPath];
    if (!tag) return;
    if (self.delegate) {
        [self.delegate guideMenuControllerRemovedFilterByTag:tag];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == ConfirmDownloadAlertViewTag) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:2 inSection:self.tagPredicates.count+1];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (buttonIndex == 1) {
            [self downloadNGZ];
        }
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.guide deleteNGZ];
        
        [[Analytics sharedClient] event:kAnalyticsEventDeleteDownloadedGuide];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(guideMenuControllerGuideDeletedNGZForGuide:)]) {
            [self.delegate guideMenuControllerGuideDeletedNGZForGuide:self.guide];
        }
        GuideViewController *gvc = (GuideViewController *)self.revealViewController;
        if (gvc && gvc.guideDelegate && [gvc.guideDelegate respondsToSelector:@selector(guideViewControllerDeletedNGZForGuide:)]) {
            [gvc.guideDelegate guideViewControllerDeletedNGZForGuide:self.guide];
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:2
                                                     inSection:self.tagPredicates.count+1];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else if (buttonIndex == 1) {
        [self downloadNGZ];
    }
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

#pragma mark - GuideMenuViewController

- (BOOL)isDownloading
{
    return self.ngzDownloadConnection != nil;
}

- (void)downloadNGZ
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [[Analytics sharedClient] event:kAnalyticsEventDownloadGuideStarted];
    
    self.ngzFilePath = self.guide.ngzPath;
    NSString *ngzURL = self.guide.ngzURL;
    NSURL *url = [NSURL URLWithString:ngzURL];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                            timeoutInterval:10*60];
    self.receivedData = [[NSMutableData alloc] initWithLength:0];
    self.ngzDownloadConnection = [[NSURLConnection alloc] initWithRequest:theRequest
                                                                   delegate:self];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:2 inSection:self.tagPredicates.count+1];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)stopDownloadNGZ
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.ngzDownloadConnection cancel];
    self.ngzDownloadConnection = nil;
    self.receivedData = nil;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:2
                                                 inSection:self.tagPredicates.count+1];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    self.lastStatusCode = httpResponse.statusCode;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if (self.progress) {
        self.progress.hidden = NO;
    }
    [self.receivedData setLength:0];
    self.expectedBytes = [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
    float progressive = (float)[self.receivedData length] / (float)self.expectedBytes;
    if (self.progress) {
        [self.progress setProgress:progressive];
    }
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to download guide",nil)
                                                 message:error.localizedDescription
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                       otherButtonTitles:nil];
    [av show];
    [self stopDownloadNGZ];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSError *error;
    if (self.progress) {
        self.progress.hidden = YES;
    }
    if (self.lastStatusCode == 200) {
        if ([self.receivedData writeToFile:self.ngzFilePath options:NSDataWritingAtomic error:&error]) {
            NSLog(@"wrote to file: %@", self.ngzFilePath);
            [[Analytics sharedClient] event:kAnalyticsEventDownloadGuideCompleted];
        } else {
            NSLog(@"failed to write to %@, error: %@", self.ngzFilePath, error);
        }
        [self extractNGZ];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to download guide",nil)
                                                     message:NSLocalizedString(@"Either there was an error on the server or the guide no longer exists.",nil)
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        [self stopDownloadNGZ];
    }
}

- (void)extractNGZ
{
    // unzip the archive
    [SSZipArchive unzipFileAtPath:self.guide.ngzPath toDestination:self.guide.dirPath];
    // reload data in collectionview
    if (self.delegate && [self.delegate respondsToSelector:@selector(guideMenuControllerGuideDownloadedNGZForGuide:)]) {
        [self.delegate guideMenuControllerGuideDownloadedNGZForGuide:self.guide];
    }
    GuideViewController *gvc = (GuideViewController *)self.revealViewController;
    if (gvc && gvc.guideDelegate && [gvc.guideDelegate respondsToSelector:@selector(guideViewControllerDownloadedNGZForGuide:)]) {
        [gvc.guideDelegate guideViewControllerDownloadedNGZForGuide:self.guide];
    }
    // reload data in menu
    [self.tableView reloadData];
    [self stopDownloadNGZ];
}

- (void)setupConstraintsForCell:(UITableViewCell *)cell{
    if(!cell.constraints.count){
        UILabel *textLabel = (UILabel *)[cell viewWithTag:DetailCellTextTag];
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        textLabel.textAlignment = NSTextAlignmentNatural;
        UILabel *detailTextLabel = (UILabel *)[cell viewWithTag:DetailCellDetailTag];
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        CGFloat leftOffset;
        CGFloat rightOffset;
        NSLocaleLanguageDirection currentLanguageDirection = [NSLocale characterDirectionForLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];
        if(currentLanguageDirection == kCFLocaleLanguageDirectionRightToLeft){
            leftOffset = 8.0;
            rightOffset = 68.0;
        }
        else{
            leftOffset = 68.0;
            rightOffset = 8.0;
        }
        
        NSDictionary *metrics = @{@"leftOffset":@(leftOffset), @"rightOffset":@(rightOffset)};
        
        NSDictionary *views = @{@"textLabel":textLabel, @"detailTextLabel":detailTextLabel};
        
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leftOffset-[textLabel]-[detailTextLabel]-rightOffset-|" options:0 metrics:metrics views:views]];
        
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[textLabel]-11-|" options:NSLayoutFormatAlignAllLeading metrics:metrics views:views]];
        
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[detailTextLabel]-11-|" options:NSLayoutFormatAlignAllTrailing metrics:metrics views:views]];
    }
}




















@end
                                    

