//
//  INObservationFormViewController.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TapkuLibrary/TapkuLibrary.h>
#import "EditLocationViewController.h"
#import "ProjectChooserViewController.h"
#import "TaxaSearchViewController.h"
#import "DCRoundSwitch.h"
#import "GuideXML.h"

@class Observation;
@class ObservationField;
@class ObservationFieldValue;
@class ObservationPhoto;
@class ObservationDetailViewController;

@protocol ObservationDetailViewControllerDelegate <NSObject>
@optional
- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller;
- (void)observationDetailViewControllerDidCancel:(ObservationDetailViewController *)controller;
@end

@interface OFVTaxaSearchControllerDelegate : NSObject <TaxaSearchViewControllerDelegate>
@property (nonatomic, weak) ObservationDetailViewController *controller;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@interface ObservationDetailViewController : UITableViewController <
    UITextFieldDelegate, 
    UITextViewDelegate, 
    UIActionSheetDelegate, 
    UINavigationControllerDelegate, 
    UIImagePickerControllerDelegate, 
    TKCoverflowViewDelegate, 
    TKCoverflowViewDataSource,
    CLLocationManagerDelegate, 
    EditLocationViewControllerDelegate,
    ProjectChooserViewControllerDelegate,
    TaxaSearchViewControllerDelegate,
    UIAlertViewDelegate>
//siguiente linea añadida por M.Lujano:29/06/2016
@property (nonatomic, strong) GuideXML *guide;
@property (nonatomic, weak) id <ObservationDetailViewControllerDelegate> delegate;
@property (nonatomic, strong) Observation *observation;
@property (nonatomic, strong) NSMutableArray *observationPhotos;
@property (nonatomic, strong) NSMutableArray *observationFieldValues;
@property (nonatomic, strong) TKCoverflowView *coverflowView;
@property (weak, nonatomic) IBOutlet UITextField *speciesGuessTextField;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *observedAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionalAccuracyLabel;
@property (weak, nonatomic) IBOutlet UITextField *placeGuessField;
@property (weak, nonatomic) IBOutlet DCRoundSwitch *idPleaseSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *geoprivacyCell;
@property (strong, nonatomic) UIToolbar *keyboardToolbar;
@property (strong, nonatomic) UIBarButtonItem *saveButton;
@property (strong, nonatomic) UIBarButtonItem *deleteButton;
@property (strong, nonatomic) UIBarButtonItem *viewButton;
@property (strong, nonatomic) UIBarButtonItem *activityBarButton;
@property (strong, nonatomic) UIButton *activityButton;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSTimer *locationTimer;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, assign) BOOL locationUpdatesOn;
@property (nonatomic, assign) BOOL observationWasNew;
@property (nonatomic, strong) NSURL *lastImageReferenceURL;
@property (nonatomic, strong) NSMutableDictionary *ofvCells;
@property (nonatomic, strong) OFVTaxaSearchControllerDelegate *ofvTaxaSearchControllerDelegate;
@property (nonatomic, strong) NSString *taxonID;
@property (nonatomic, assign) BOOL didClickCancel;

@property (nonatomic, assign) BOOL shouldShowBigSaveButton;

- (void)focusOnPrevField;
- (void)focusOnNextField;
- (BOOL)focusOnFieldAtIndexPath:(NSIndexPath *)indexPath;
- (void)keyboardDone;
- (void)clickedSave;
- (void)clickedDelete;
- (void)clickedView;
- (void)clickedActivity:(id)sender;
- (IBAction)clickedCancel:(id)sender;
- (IBAction)clickedAddPhoto:(id)sender;
- (IBAction)clickedSpeciesButton:(id)sender;
- (void)save;
- (void)observationToUI;
- (void)uiToObservation;
- (UIViewController *)getToolbarViewController;

- (void)addPhoto:(ObservationPhoto *)op;
- (void)removePhoto:(ObservationPhoto *)op;
- (void)refreshCoverflowView;
- (void)reverseGeocodeCoordinates;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (void)locationActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)deleteActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)viewActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)geoprivacyActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

- (void)dismissActionSheet;
- (NSDictionary *)getGPSDictionaryForLocation:(CLLocation *)location;

- (UITableViewCell *)tableView:(UITableView *)tableView projectCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView observationFieldValueCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)projectsRequireField:(ObservationField *)observationField;
- (ObservationFieldValue *)observationFieldValueForIndexPath:(NSIndexPath *)indexPath;
- (void)clearCurrentObservationField;

@end
