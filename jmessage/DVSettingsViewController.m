//
//  DVSettingsViewController.m
//  iostest
//
//  Created by Mogura on 12/7/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "SBJson.h"
#import "JASidePanelController.h"

#import "DVSettingsViewController.h"
#import "DVAPIWrapper.h"
#import "DVDownloader.h"
#import "DVConstants.h"
#import "DVMacros.h"

@interface DVSettingsViewController () {
    DVAPIWrapper *apiWrapper;
}
- (void) hideKeyboard;
- (void) onMessageSavedSuccessfully;
@end

@implementation DVSettingsViewController
@synthesize usernameTextField;
@synthesize messageTextField;

#pragma mark - Initialization Code
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self->apiWrapper = [[DVAPIWrapper alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // accept a tap on the parent view so we can hide the keyboard when the user clicks away to hide it
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    // load settings
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"username"] != nil) {
        usernameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
        DLog(@"Loaded username '%@' from NSUserDefaults", usernameTextField.text);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setUsernameTextField:nil];
    [self setMessageTextField:nil];
    [super viewDidUnload];
}

#pragma mark - DVAPIWrapper Calls
- (IBAction) sendTextMessage:(id)sender {
    DVTextMessage *newMsg = [[DVTextMessage alloc] init];
    newMsg.username = usernameTextField.text;
    newMsg.messageText = messageTextField.text;
    
    [self->apiWrapper sendMessage:newMsg AndCallBlock:^(NSError *error, DVTextMessage *msg) {
        if (error != nil) {
            DLog(@"Received error '%@'", [error localizedDescription]);
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"error"
                                                         message:[error localizedDescription]
                                                        delegate:nil
                                               cancelButtonTitle:@"ok"
                                               otherButtonTitles:nil];
            [av show];
        } else {
            [self performSelector:@selector(onMessageSavedSuccessfully) withObject:nil afterDelay:1];
        }
    }];
}

- (void) onMessageSavedSuccessfully {
    // this class is used as a left sliding panel, so we want to close ourselfs sometimes
    JASidePanelController *parent = (JASidePanelController *)[self parentViewController];
    [parent toggleLeftPanel:nil];
    
    messageTextField.text = @"";
}

#pragma mark - UITextField Delegates
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isEqual:usernameTextField]) {
        DLog(@"Saving username '%@' to defaults", usernameTextField.text);
        [[NSUserDefaults standardUserDefaults] setObject:usernameTextField.text forKey:@"username"];
    }
}

-(void) hideKeyboard {
    [usernameTextField resignFirstResponder];
    [messageTextField resignFirstResponder];
}

@end
