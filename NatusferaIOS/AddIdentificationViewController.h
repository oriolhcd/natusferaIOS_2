//
//  AddIdentificationViewController.h
//  Natusfera
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaxaSearchViewController.h"
#import "ObservationVisualization.h"

@interface AddIdentificationViewController : UITableViewController <TaxaSearchViewControllerDelegate>

@property (nonatomic, strong) id <ObservationVisualization> observation;
@property (nonatomic, strong) Taxon *taxon;

@end
