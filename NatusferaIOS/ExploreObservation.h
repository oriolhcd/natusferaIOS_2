//
//  ExploreObservation.h
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "ObservationVisualization.h"
#import "Uploadable.h"
#import "Taxon.h"

@interface ExploreObservation : NSObject <MKAnnotation, ObservationVisualization, Uploadable>

@property (nonatomic, assign) NSInteger observationId;
@property (nonatomic, copy) NSString *speciesGuess;
@property (nonatomic, copy) NSString *iconicTaxonName;
@property (nonatomic, copy) NSString *taxonName;
@property (nonatomic, copy) NSString *inatDescription;
@property (nonatomic, assign) NSInteger taxonId;
@property (nonatomic, copy) NSString *taxonRank;
@property (nonatomic, copy) NSString *commonName;
@property (nonatomic, copy) NSArray *observationPhotos;
@property (nonatomic, copy) NSDate *timeObservedAt;
@property (nonatomic, copy) NSDate *observedOn;
@property (nonatomic, copy) NSString *qualityGrade;
@property (nonatomic, assign) BOOL idPlease;
@property (nonatomic, assign) NSInteger identificationsCount;
@property (nonatomic, assign) NSInteger commentsCount;
@property (nonatomic, copy) NSArray *identifications;
@property (nonatomic, copy) NSArray *comments;
@property (nonatomic, copy) NSArray *faves;
@property (nonatomic, assign) BOOL mappable;
@property (nonatomic, assign) NSInteger publicPositionalAccuracy;
@property (nonatomic, assign) BOOL coordinatesObscured;
@property (nonatomic, copy) NSString *placeGuess;

@property (nonatomic, copy) NSString *locationCoordinateString;

@property (nonatomic, assign) NSInteger observerId;
@property (nonatomic, copy) NSString *observerName;
@property (nonatomic, copy) NSString *observerIconUrl;

@property (nonatomic, readonly) CLLocationCoordinate2D coords;

@property (nonatomic, readonly) BOOL hasTime;

@property (nonatomic, readonly) BOOL commentsAndIdentificationsSynchronized;

@property (nonatomic) Taxon *taxon;

@end
