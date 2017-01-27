//
//  ObsDetailActivityViewModel.m
//  Natusfera
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <YLMoment/YLMoment.h>

#import "ObsDetailActivityViewModel.h"
#import "Observation.h"
#import "DisclosureCell.h"
#import "User.h"
#import "Taxon.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "ObsDetailActivityMoreCell.h"
#import "UIColor+Natusfera.h"
#import "ObsDetailActivityAuthorCell.h"
#import "ObsDetailActivityBodyCell.h"
#import "ObsDetailAddActivityFooter.h"
#import "ObsDetailTaxonCell.h"
#import "NatusferaAppDelegate.h"
#import "LoginController.h"
#import "NSURL+Natusfera.h"
#import "Analytics.h"
#import "ObsDetailNoInteractionHeaderFooter.h"
#import "IdentificationVisualization.h"
#import "CommentVisualization.h"
#import "ActivityVisualization.h"
#import "ExploreComment.h"
#import "UIImage+Natusfera.h"

@interface ObsDetailActivityViewModel () <RKRequestDelegate> {
    BOOL hasSeenNewActivity;
}
@end

@implementation ObsDetailActivityViewModel

#pragma mark - uiviewcontroller lifecycle

- (void)dealloc {
    [[[RKObjectManager sharedManager] requestQueue] cancelRequestsWithDelegate:self];
}

#pragma mark - uitableview datasource/delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else {
        if (self.observation.sortedActivity.count == 0) {
            // if activity hasn't been loaded from the server yet
            return 0;
        }
        id <ActivityVisualization> activity = [self activityForSection:section];
        if ([activity conformsToProtocol:@protocol(CommentVisualization)]) {
            return 2;
        } else if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
            id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;

            NSInteger baseRows = 3;
            
            Taxon *myIdTaxon = [self taxonForIdentificationByLoggedInUser];
            // can't agree with my ID, can't agree with an ID that matches my own
            if ([self loggedInUserProducedActivity:activity] || (myIdTaxon && [myIdTaxon.recordID isEqual:@([identification taxonId])])) {
                // can't agree with your own identification
                // so don't show row with agree button
                baseRows--;
            }

            if (identification.body && identification.body.length > 0) {
                baseRows++;
            }
            
            return baseRows;
        } else {
            // impossibru
            return 0;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // each comment/id is its own section
    return [super numberOfSectionsInTableView:tableView] + self.observation.sortedActivity.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView heightForHeaderInSection:section];
    } else if (section == 2) {
        return 0;
    } else {
        return 30;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == self.observation.sortedActivity.count + 1) {
        return 64;
    } else {
        return CGFLOAT_MIN;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == self.observation.sortedActivity.count + 1) {
        if (self.observation.inatRecordId) {
            ObsDetailAddActivityFooter *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"addActivityFooter"];
            [footer.commentButton addTarget:self
                                     action:@selector(addComment)
                           forControlEvents:UIControlEventTouchUpInside];
            [footer.suggestIDButton addTarget:self
                                       action:@selector(addIdentification)
                             forControlEvents:UIControlEventTouchUpInside];
            return footer;
        } else {
            NSString *noInteraction;

            NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
            if (appDelegate.loginController.isLoggedIn) {
                noInteraction = NSLocalizedString(@"Upload this observation to enable comments & identifications.", nil);
            } else {
                noInteraction = NSLocalizedString(@"Login and upload this observation to enable comments & identifications.", nil);
            }
            
            ObsDetailNoInteractionHeaderFooter *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"noInteraction"];
            footer.noInteractionLabel.text = noInteraction;
            return footer;
        }
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    } else {
        id <ActivityVisualization> activity = [self activityForSection:indexPath.section];
        if ([activity conformsToProtocol:@protocol(CommentVisualization)]) {
            if (indexPath.item == 0) {
                // size for user/date
                return 44;
            } else {
                // body row
                return [self heightForRowInTableView:tableView withBodyText:activity.body];
            }
        } else {
            // identification
            if (indexPath.item == 1) {
                // taxon
                return 60;
            }
            if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == 4) {
                // contains body
                if (indexPath.item == 2) {
                    // body row
                    return [self heightForRowInTableView:tableView withBodyText:activity.body];
                } else {
                    // user/date, agree/action
                    return 44;
                }
            } else {
                // no body row, everything else 44
                return 44;
            }
        }
    }
}

- (CGFloat)heightForRowInTableView:(UITableView *)tableView withBodyText:(NSString *)text {
    // 22 for some padding on the left/right
    CGFloat usableWidth = tableView.bounds.size.width - 22;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:14.0f];
    
    CGRect textRect = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{ NSFontAttributeName: font }
                                         context:nil];
    
    // 20 for padding above/below
    return MAX(44, textRect.size.height + 20);
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView viewForHeaderInSection:section];
    } else {
        UITableViewHeaderFooterView *view = [UITableViewHeaderFooterView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin;
        view.frame = CGRectMake(0, 0, tableView.bounds.size.width, 30);
        [view addSubview:({
            UIView *thread = [UIView new];
            thread.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin;
            thread.frame = CGRectMake(15 + 27 / 2.0 - 5, 0, 7, 30);
            thread.backgroundColor = [UIColor colorWithHexString:@"#d8d8d8"];
            thread;
        })];
        return view;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        if (indexPath.item == 0) {
            // each section starts with an author row
            return [self authorCellInTableView:tableView
                                  withActivity:[self activityForSection:indexPath.section]];
        } else if (indexPath.item == 1) {
            id <ActivityVisualization> activity = [self activityForSection:indexPath.section];
            if ([activity conformsToProtocol:@protocol(CommentVisualization)]) {
                // comments follow with a body row
                return [self activityBodyCellInTableView:tableView
                                            withBodyText:activity.body];
            } else if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
                // identifications follow with a taxon row
                return [self taxonCellInTableView:tableView
                               withIdentification:(id <IdentificationVisualization>)activity];
            }
        } else if (indexPath.item == 2) {
            // must be identification
            id <IdentificationVisualization> i = (id <IdentificationVisualization>)[self activityForSection:indexPath.section];
            if (i.body && i.body.length > 0) {
                // this id has a text body
                return [self activityBodyCellInTableView:tableView
                                            withBodyText:i.body];
            } else {
                // the "more" cell for ids, currently has an agree button
                return [self moreCellInTableView:tableView
                                    withActivity:[self activityForSection:indexPath.section]];
            }
        } else if (indexPath.item == 3) {
            // the "more" cell for ids, currently has an agree button
            return [self moreCellInTableView:tableView
                                withActivity:[self activityForSection:indexPath.section]];
        } else {
            // impossibru!
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetail"];

            return cell;
        }
    }
    return 0; //mlb
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [tableView numberOfSections] - 1) {
        if (!hasSeenNewActivity) {
            [self markActivityAsSeen];
            hasSeenNewActivity = YES;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // second row in an identification section is a taxon row, which is selectable
    if (indexPath.item == 1) {
        id <ActivityVisualization> activity = [self activityForSection:indexPath.section];
        if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
            id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;
            
            [self.delegate inat_performSegueWithIdentifier:@"taxon" sender:@([identification taxonId])];
        }
    }
}

#pragma mark - section helpers

- (id <ActivityVisualization>)activityForSection:(NSInteger)section {
    // first 2 sections are for observation metadata
    return self.observation.sortedActivity[section - 2];
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionActivity;
}

#pragma mark - tableviewcell helpers

- (ObsDetailActivityBodyCell *)activityBodyCellInTableView:(UITableView *)tableView withBodyText:(NSString *)bodyText {
    // body
    ObsDetailActivityBodyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityBody"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSError *err = nil;
    NSDictionary *opts = @{
                           NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                           NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding),
                           };
    NSMutableAttributedString *body = [[[NSAttributedString alloc] initWithData:[bodyText dataUsingEncoding:NSUTF8StringEncoding]
                                                                        options:opts
                                                             documentAttributes:nil
                                                                          error:&err] mutableCopy];
    
    // reading the text as HTML gives it a with-serif font
    [body addAttribute:NSFontAttributeName
                 value:[UIFont systemFontOfSize:14]
                 range:NSMakeRange(0, body.length)];
    
    cell.bodyTextView.attributedText = body;

    cell.bodyTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    cell.bodyTextView.editable = NO;
    cell.bodyTextView.scrollEnabled = NO;
        
    return cell;
}

- (ObsDetailActivityAuthorCell *)authorCellInTableView:(UITableView *)tableView withActivity:(id <ActivityVisualization>)activity {
    ObsDetailActivityAuthorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityAuthor"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (activity) {
        NSURL *userIconUrl = [activity userIconUrl];
        if (userIconUrl) {
            [cell.authorImageView sd_setImageWithURL:userIconUrl];
            cell.authorImageView.layer.cornerRadius = 27.0 / 2;
            cell.authorImageView.clipsToBounds = YES;
        } else {
            cell.authorImageView.image = [UIImage inat_defaultUserImage];
        }
        
        YLMoment *moment = [YLMoment momentWithDate:activity.createdAt];
        cell.dateLabel.text = [moment fromNowWithSuffix:NO];
        cell.dateLabel.textColor = [UIColor lightGrayColor];

        if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
            // TODO: push this down into protocol implementation
            id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;
            NSString *identificationAuthor = [NSString stringWithFormat:NSLocalizedString(@"%@'s ID", @"identification author attribution"), [identification userName]];
            cell.authorNameLabel.text = identificationAuthor;
        } else {
            cell.authorNameLabel.text = [activity userName];
        }
    }

    return cell;
}

- (ObsDetailActivityMoreCell *)moreCellInTableView:(UITableView *)tableView withActivity:(id <ActivityVisualization>)activity {
    ObsDetailActivityMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityMore"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
        // TODO: push this down into protocol implementation
        id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;
        
        // can't agree with your identification
        cell.agreeButton.enabled = ![self loggedInUserProducedActivity:activity];
        
        Taxon *t = [self taxonForIdentificationByLoggedInUser];
        if (t) {
            // can't agree with an identification that matches your own
            if ([t.recordID isEqual:@([identification taxonId])]) {
                cell.agreeButton.enabled = NO;
            }
        }
        
        cell.agreeButton.tag = [identification taxonId];
    }
    
    [cell.agreeButton addTarget:self
                         action:@selector(agree:)
               forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (ObsDetailTaxonCell *)taxonCellInTableView:(UITableView *)tableView withIdentification:(id <IdentificationVisualization>)identification {

    ObsDetailTaxonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxonFromNib"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    if (![identification taxonCommonName]) {
        // no common name, so only show scientific name in the main label
        cell.taxonNameLabel.text = [identification taxonScientificName];
        cell.taxonSecondaryNameLabel.text = nil;
        
        if ([identification taxonRankLevel] > 0 && [identification taxonRankLevel] <= 20) {
            cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:17];
            cell.taxonNameLabel.text = [identification taxonScientificName];
        } else {
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            cell.taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                        [[identification taxonRank] capitalizedString],
                                        [identification taxonScientificName]];
        }
    } else {
        // show both common & scientfic names
        cell.taxonNameLabel.text = [identification taxonCommonName];
        cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
        
        if ([identification taxonRankLevel] > 0 && [identification taxonRankLevel] <= 20) {
            cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:14];
            cell.taxonSecondaryNameLabel.text = [identification taxonScientificName];
        } else {
            cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
            cell.taxonSecondaryNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                                 [[identification taxonRank] capitalizedString],
                                                 [identification taxonScientificName]];
            
        }
    }
    
    [cell.taxonImageView sd_setImageWithURL:[identification taxonIconUrl]];
    
    NSPredicate *taxonPredicate = [NSPredicate predicateWithFormat:@"recordID == %ld", [identification taxonId]];
    Taxon *taxon = [[Taxon objectsWithPredicate:taxonPredicate] firstObject];

    
    if (taxon) {
        
        if ([taxon.name isEqualToString:taxon.defaultName] || taxon.defaultName == nil) {
            // no common name, so only show scientific name in the main label
            cell.taxonNameLabel.text = taxon.name;
            cell.taxonSecondaryNameLabel.text = nil;
            
            if (taxon.isGenusOrLower) {
                cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:17];
                cell.taxonNameLabel.text = taxon.name;
            } else {
                cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
                cell.taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                            [taxon.rank capitalizedString], taxon.name];
            }
        } else {
            // show both common & scientfic names
            cell.taxonNameLabel.text = taxon.defaultName;
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            
            if (taxon.isGenusOrLower) {
                cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:14];
                cell.taxonSecondaryNameLabel.text = taxon.name;
            } else {
                cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
                cell.taxonSecondaryNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                                     [taxon.rank capitalizedString], taxon.name];
                
            }
        }
        
        
        if (!identification.isCurrent) {
            NSDictionary *strikeThrough = @{
                                            NSStrikethroughStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle],
                                            NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                            };
            
            if (cell.taxonNameLabel.text) {
                cell.taxonNameLabel.attributedText = [[NSAttributedString alloc] initWithString:cell.taxonNameLabel.text
                                                                                     attributes:strikeThrough];
            }
            if (cell.taxonSecondaryNameLabel.text) {
                cell.taxonSecondaryNameLabel.attributedText = [[NSAttributedString alloc] initWithString:cell.taxonSecondaryNameLabel.text
                                                                                              attributes:strikeThrough];
            }

        }
        
        if ([taxon.isIconic boolValue]) {
            cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        } else if (taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = taxon.taxonPhotos.firstObject;
            [cell.taxonImageView sd_setImageWithURL:[NSURL URLWithString:tp.thumbURL]];
        } else {
            cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark - uibutton targets

- (void)addComment {
    if (![[RKClient sharedClient] reachabilityObserver].isNetworkReachable) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't Comment", nil)
                                    message:NSLocalizedString(@"Network is required.", @"Network is required error message")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't Comment", nil)
                                    message:NSLocalizedString(@"You must be logged in.", @"Account is required error message")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }

    [self.delegate inat_performSegueWithIdentifier:@"addComment" sender:nil];
}

- (void)addIdentification {
    if (![[RKClient sharedClient] reachabilityObserver].isNetworkReachable) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't Add ID", nil)
                                    message:NSLocalizedString(@"Network is required.", @"Network is required error message")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't Add ID", nil)
                                    message:NSLocalizedString(@"You must be logged in.", @"Account is required error message")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }

    [self.delegate inat_performSegueWithIdentifier:@"addIdentification" sender:nil];
}

- (void)agree:(UIButton *)button {
    if (![[RKClient sharedClient] reachabilityObserver].isNetworkReachable) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't Agree", nil)
                                    message:NSLocalizedString(@"Network is required.", @"Network is required error message")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't Agree", nil)
                                    message:NSLocalizedString(@"You must be logged in.", @"Account is required error message")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }

    // add an identification
    [[Analytics sharedClient] debugLog:@"Network - Obs Detail Add Comment"];
    [[Analytics sharedClient] event:kAnalyticsEventObservationAddIdentification
                     withProperties:@{ @"Via": @"View Obs Agree" }];
    
    NSDictionary *params = @{
                             @"identification[observation_id]": self.observation.inatRecordId,
                             @"identification[taxon_id]": @(button.tag),
                             };
    
    [self.delegate showProgressHud];
    
    [[RKClient sharedClient] post:@"/identifications"
                           params:params
                         delegate:self];
}

#pragma mark - misc helpers

- (void)markActivityAsSeen {
    // check for network
    if (self.observation.inatRecordId && self.observation.hasUnviewedActivity.boolValue && [self.observation isKindOfClass:[Observation class]]) {
        Observation *obs = (Observation *)self.observation;
        
        [[Analytics sharedClient] debugLog:@"Network - Viewed Updates"];
        [[RKClient sharedClient] put:[NSString stringWithFormat:@"/observations/%@/viewed_updates.json", self.observation.inatRecordId]
                              params:nil
                            delegate:self];
        obs.hasUnviewedActivity = [NSNumber numberWithBool:NO];
        NSError *error = nil;
        [[[RKObjectManager sharedManager] objectStore] save:&error];
    }
}

- (BOOL)loggedInUserProducedActivity:(id <ActivityVisualization>)activity {
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        User *loggedInUser = [login fetchMe];
        if ([loggedInUser.login isEqualToString:[activity userName]]) {
            return YES;
        }
    }
    return NO;
}

- (Taxon *)taxonForIdentificationByLoggedInUser {
    // get "my" current identification
    NatusferaAppDelegate *appDelegate = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        User *loggedInUser = [login fetchMe];
        for (id <IdentificationVisualization> eachId in self.observation.identifications) {
            if ([[eachId userName] isEqualToString:loggedInUser.login] && [eachId isCurrent]) {
                
                NSPredicate *taxonPredicate = [NSPredicate predicateWithFormat:@"recordID == %ld", [eachId taxonId]];
                Taxon *taxon = [[Taxon objectsWithPredicate:taxonPredicate] firstObject];
                
                return taxon;
            }
        }
    }
    return nil;
}

#pragma mark - RKRequestDelegate

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    
    [self.delegate hideProgressHud];

    // set "seen" call returns 204 on success, add ID returns 200
    if (response.statusCode == 200 || response.statusCode == 204) {
        // either id or refresh activity, reload the UI for the obs if the request succeeded
        [self.delegate reloadObservation];
    } else {
        if ([response.URL.absoluteString rangeOfString:@"/identifications"].location != NSNotFound) {
            // identification
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                        message:NSLocalizedString(@"An unknown error occured. Please try again.", @"unknown error adding ID")
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        } else {
            // refresh activity
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                        message:NSLocalizedString(@"An unknown error occured. Please try again.", @"unknown error adding ID")
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    [self.delegate hideProgressHud];
    
    if ([request.URL.absoluteString rangeOfString:@"/identifications"].location != NSNotFound) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                    message:error.localizedDescription
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    } else {
        // refresh activity
    }
}



@end
