//
//  DVRootViewController.h
//  iostest
//
//  Created by Mogura on 12/6/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefreshTableViewController.h"

@interface DVRootViewController : PullRefreshTableViewController


@property (strong, nonatomic) NSMutableArray *connections;
@property (strong, nonatomic) NSArray *messages;

- (void) finishedDownloading: (NSNotification *) notification;

@end
