//
//  DVSettingsViewController.h
//  iostest
//
//  Created by Mogura on 12/7/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DVDownloader.h"

@interface DVSettingsViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSMutableArray *connections;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;

- (void) finishedDownloading: (NSNotification *) notification;
- (IBAction) sendTextMessage:(id)sender;

@end
