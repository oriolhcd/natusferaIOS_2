//
//  ObsDetailMapCell.h
//  Natusfera
//
//  Created by Alex Shepard on 12/8/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

@import MapKit;

#import <UIKit/UIKit.h>

@interface ObsDetailMapCell : UITableViewCell

@property IBOutlet UILabel *locationNameLabel;
@property IBOutlet UIView *locationNameContainer;
@property IBOutlet UILabel *geoprivacyLabel;
@property IBOutlet MKMapView *mapView;
@property IBOutlet UILabel *noLocationLabel;

@end
