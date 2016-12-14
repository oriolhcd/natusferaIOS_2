//
//  NewsItemViewController.h
//  Natusfera
//
//  Created by Alex Shepard on 1/15/16.
//  Copyright © 2016 Natusfera. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewsItem;

@interface NewsItemViewController : UIViewController <UIWebViewDelegate>

@property IBOutlet UIWebView *postBodyWebView;

@property NewsItem *newsItem;

@end
