//
//  NewsItem.h
//  Natusfera
//
//  Created by Alex Shepard on 1/27/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import "INatModel.h"

@class User;

@interface NewsItem : INatModel

@property (nonatomic, retain) NSString *parentIconUrl;
@property (nonatomic, retain) NSString *parentProjectTitle;
@property (nonatomic, retain) NSNumber *parentRecordID;
@property (nonatomic, retain) NSString *parentSiteShortName;
@property (nonatomic, retain) NSString *parentTypeString;

@property (nonatomic, retain) NSString *postBody;
@property (nonatomic, retain) NSDate *postPublishedAt;
@property (nonatomic, retain) NSString *postTitle;
@property (nonatomic, retain) NSString *postPlainTextExcerpt;
@property (nonatomic, retain) NSString *postCoverImageUrl;

@property (nonatomic, retain) NSString *authorLogin;
@property (nonatomic, retain) NSString *authorIconUrl;

@property (nonatomic, retain) NSNumber *recordID;
@property (nonatomic, retain) NSDate *syncedAt;
@property (nonatomic, retain) NSDate *localUpdatedAt;

- (NSString *)parentTitleText;

@end
