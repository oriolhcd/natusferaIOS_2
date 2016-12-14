//
//  PartnerController.h
//  Natusfera
//
//  Created by Alex Shepard on 6/16/15.
//  Copyright © 2015 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Partner;

@interface PartnerController : NSObject

@property NSArray *partners;

// see http://www.itu.int/dms_pub/itu-t/opb/sp/T-SP-E.212A-2012-PDF-E.pdf
- (Partner *)partnerForMobileCountryCode:(NSString *)mobileCountryCode;
- (Partner *)partnerForSiteId:(NSInteger)siteId;
@end
