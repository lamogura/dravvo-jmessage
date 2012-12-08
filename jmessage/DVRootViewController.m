//
//  DVRootViewController.m
//  iostest
//
//  Created by Mogura on 12/6/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "SBJson.h"
#import "JASidePanelController.h"

#import "DVRootViewController.h"
#import "DVDownloader.h"
#import "DVConstants.h"

@interface DVRootViewController ()

@end

@implementation DVRootViewController
@synthesize connections;
@synthesize messages;

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
    
    self.title = @"jMessage Queue";
    
    // want to watch for when we are sliding back to main window so we can refresh the messages
    JASidePanelController *parent = (JASidePanelController *)[[self parentViewController] parentViewController];
    [parent addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    
    [self refresh];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark - Key Value Observing
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"state"] && [[change objectForKey:@"new"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
        NSLog(@"observed a slide back to main window");
        [self refresh];
    }
}

#pragma mark - PullToRefresh Overloads
- (void) refresh {
    NSString *urlString = [NSString stringWithFormat:@"%@/message/all", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    
    [self.connections addObject:downloader];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedDownloading:) name:@"downloadFinished" object:downloader];
    
    NSLog(@"starting connection...");
    [downloader.connection start];
}

#pragma mark - Download Request Handling
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
        self.messages = [jsonString JSONValue];
        NSLog(@"Cointained %d messages.", [self.messages count]);
    }
    
    [self.connections removeObject:downloader];
    [self stopLoading];
    [self.tableView reloadData];
}

#pragma mark - TableView Datasource Code
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messages count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"msgCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    NSDictionary *msg = [self.messages objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", [msg objectForKey:@"username"], [msg objectForKey:@"message_text"]];
    cell.detailTextLabel.text = [msg objectForKey:@"receivedAt"];

    return cell;
}

@end
