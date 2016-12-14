//
//  ExploreComment.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 Natusfera. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CommentVisualization.h"
#import "ActivityVisualization.h"

@interface ExploreComment : NSObject <CommentVisualization>

@property (nonatomic, assign) NSInteger commentId;
@property (nonatomic, copy) NSString *commentText;
@property (nonatomic, copy) NSString *commenterName;
@property (nonatomic, assign) NSInteger commenterId;
@property (nonatomic, copy) NSString *commenterIconUrl;
@property (nonatomic, copy) NSDate *commentedDate;

@end
