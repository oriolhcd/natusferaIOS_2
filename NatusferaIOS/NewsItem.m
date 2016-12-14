//
//  NewsItem.m
//  Natusfera
//
//  Created by Alex Shepard on 1/27/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <NSString_stripHtml/NSString_stripHTML.h>

#import "NewsItem.h"
#import "User.h"

static RKManagedObjectMapping *defaultMapping = nil;

@implementation NewsItem

@dynamic parentIconUrl;
@dynamic parentProjectTitle;
@dynamic parentRecordID;
@dynamic parentSiteShortName;
@dynamic parentTypeString;

@dynamic postBody;
@dynamic postPublishedAt;
@dynamic postTitle;
@dynamic postPlainTextExcerpt;
@dynamic postCoverImageUrl;

@dynamic authorLogin;
@dynamic authorIconUrl;

@dynamic recordID;
@dynamic syncedAt;
@dynamic localUpdatedAt;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class]
                                            inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
                
        [defaultMapping mapKeyPath:@"parent.icon_url" toAttribute:@"parentIconUrl"];
        [defaultMapping mapKeyPath:@"parent.title" toAttribute:@"parentProjectTitle"];
        [defaultMapping mapKeyPath:@"parent_id" toAttribute:@"parentRecordID"];
        [defaultMapping mapKeyPath:@"parent.site_name_short" toAttribute:@"parentSiteShortName"];
        [defaultMapping mapKeyPath:@"parent_type" toAttribute:@"parentTypeString"];

        [defaultMapping mapKeyPath:@"body" toAttribute:@"postBody"];
        [defaultMapping mapKeyPath:@"published_at" toAttribute:@"postPublishedAt"];
        [defaultMapping mapKeyPath:@"title" toAttribute:@"postTitle"];
        
        [defaultMapping mapKeyPath:@"user.login" toAttribute:@"authorLogin"];
        [defaultMapping mapKeyPath:@"user.user_icon_url" toAttribute:@"authorIconUrl"];
        
        [defaultMapping mapKeyPath:@"id"
                       toAttribute:@"recordID"];
                
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

- (NSString *)parentTitleText {
    if ([self.parentTypeString isEqualToString:@"Site"]) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ News", @"site news"), self.parentSiteShortName];
    } else if ([self.parentTypeString isEqualToString:@"Project"]) {
        return self.parentProjectTitle;
    } else {
        return @"";
    }
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    
    if (!self.postPlainTextExcerpt) {
        NSString *strippedBody = [self.postBody stringByStrippingHTML];
        self.postPlainTextExcerpt = [strippedBody stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        // this is also a good time to see if there's an embedded image
        NSString *urlString = nil;
        NSString *htmlString = self.postBody;
        NSScanner *theScanner = [NSScanner scannerWithString:htmlString];
        // find start of IMG tag
        [theScanner scanUpToString:@"<img" intoString:nil];
        if (![theScanner isAtEnd]) {
            [theScanner scanUpToString:@"src" intoString:nil];
            NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
            [theScanner scanUpToCharactersFromSet:charset intoString:nil];
            [theScanner scanCharactersFromSet:charset intoString:nil];
            [theScanner scanUpToCharactersFromSet:charset intoString:&urlString];
            NSURL *imageURL = [NSURL URLWithString:urlString];
            if (imageURL) {
                self.postCoverImageUrl = urlString;
            }
        }
    }
}

@end
