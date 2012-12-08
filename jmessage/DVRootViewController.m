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
#import "DVAPIWrapper.h"
#import "DVDownloader.h"
#import "DVConstants.h"
#import "DVTextMessage.h"

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
        NSLog(@"Observed a slide back to center panel, refreshing...");
        [self refresh];
    }
}

#pragma mark - PullToRefresh Overloads
- (void) refresh {
    DVAPIWrapper *api = [[DVAPIWrapper alloc] init];
    [api getAllMessagesAndCallBlock:^(NSError *err, NSArray *msgs) {
        if (err != nil) {
            NSLog(@"Received error '%@'", [err localizedDescription]);
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"error"
                                                         message:[err localizedDescription]
                                                        delegate:nil
                                               cancelButtonTitle:@"ok"
                                               otherButtonTitles:nil];
            [av show];
        } else {
            self.messages = msgs;
            [self stopLoading];
            [self.tableView reloadData];
        }
    }];
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

    DVTextMessage *msg = [self.messages objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", msg.username, msg.messageText];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MMM d, yyyy @ H:mm:ss";
    cell.detailTextLabel.text = [formatter stringFromDate:msg.receivedAt];

    return cell;
}

@end
