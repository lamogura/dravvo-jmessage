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
#import "DVDownloader.h"
#import "DVConstants.h"

@interface DVSettingsViewController ()
- (void) hideKeyboard;
- (void) messageSavedSuccessfully;
@end

@implementation DVSettingsViewController
@synthesize usernameTextField;
@synthesize messageTextField;

#pragma mark - Initialization Code
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
        NSLog(@"Loaded username '%@' from NSUserDefaults", usernameTextField.text);
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

#pragma mark - Download Request Handling
- (IBAction) sendTextMessage:(id)sender {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/message/new", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *dataString = [NSString stringWithFormat:@"username=%@&message_text=%@",[usernameTextField text], [messageTextField text]];
    NSString *dataLength = [NSString stringWithFormat:@"%d", [dataString length]];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [req setHTTPMethod:@"POST"];
    [req setValue:dataLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:data];
    
    NSLog(@"POST to '%@' with body '%@'", urlString, dataString);
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    [self.connections addObject:downloader];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedDownloading:) name:@"downloadFinished" object:downloader];
   
    [downloader.connection start]; // setup to have to start manually
}

- (void) finishedDownloading: (NSNotification *) notification {
    DVDownloader *downloader = [notification object];
    if (notification.userInfo) {
        NSError *err = [notification.userInfo objectForKey:@"error"];
        NSLog(@"Received error '%@'", [err localizedDescription]);
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"error"
                                                     message:[err localizedDescription]
                                                    delegate:nil
                                           cancelButtonTitle:@"ok"
                                           otherButtonTitles:nil];
        [av show];
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
        NSLog(@"Received JSON response: %@", jsonString);
        NSDictionary *resp = [jsonString JSONValue];
        if ([resp valueForKey:@"error"] != nil) {
            NSString *errorString = [[resp objectForKey:@"error"] objectForKey:@"message"];
            NSLog(@"Contained an error: %@", errorString);
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:errorString
                                                        delegate:nil
                                               cancelButtonTitle:@"ok"
                                               otherButtonTitles:nil];
            [av show];
        } else {
            NSLog(@"POST message saved successfully.");

            // TODO: this is only to simulate a reload time, should actually try to wait until a reload
            [self performSelector:@selector(messageSavedSuccessfully) withObject:nil afterDelay:1];
        }
    }
    
    [self.connections removeObject:downloader];
}

- (void) messageSavedSuccessfully {
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
        NSLog(@"Saving username '%@' to defaults", usernameTextField.text);
        [[NSUserDefaults standardUserDefaults] setObject:usernameTextField.text forKey:@"username"];
    }
}

-(void) hideKeyboard {
    [usernameTextField resignFirstResponder];
    [messageTextField resignFirstResponder];
}

@end
