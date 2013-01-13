//
//  DVAppDelegate.m
//  iostest
//
//  Created by mogura on 12/2/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "DVAppDelegate.h"
#import "DVRootViewController.h"
#import "JASidePanelController.h"
#import "DVSettingsViewController.h"

#import "DVDownloader.h"
#import "DVConstants.h"
#import "DVMacros.h"
#import "DVUtils.h"

@interface DVAppDelegate () {
    NSMutableSet *connections; // downloader connections live
}
@end

@implementation DVAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[JASidePanelController alloc] init];
    self.viewController.shouldDelegateAutorotateToVisiblePanel = NO;
    
    DVRootViewController *rootViewController = [[DVRootViewController alloc] initWithStyle:UITableViewStylePlain];
    self.viewController.centerPanel = [[UINavigationController alloc] initWithRootViewController:rootViewController];
        
    self.viewController.leftPanel = [[DVSettingsViewController alloc] initWithNibName:@"DVSettingsViewController" bundle:nil];

    self.window.rootViewController = self.viewController;

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

    [self.window makeKeyAndVisible];
    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *urlString = [NSString stringWithFormat:@"%@/apns/register", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *dataString = [NSString stringWithFormat:@"deviceToken=%@", [DVUtils hexadecimalStringFromData:deviceToken]];
    NSString *dataLength = [NSString stringWithFormat:@"%d", [dataString length]];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [req setHTTPMethod:@"POST"];
    [req setValue:dataLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:data];

    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    DLog(@"POST to '%@'", urlString);
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:DVDownloaderDidFinishDownloading object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        if (notification.userInfo) {
            NSError *err = [notification.userInfo objectForKey:@"error"];
            DLog(@"%@", [err localizedDescription]);
        } else {
            DLog(@"Sucessfully registered device token with Dravvo server.");
            // TODO: we should stop registering in the future once this device succesffully saved on the server
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didRegisterAPNS"];
            [self performSelector:@selector(removeAllDVDownloadObservers) withObject:nil afterDelay:1];
        }
    }];

    [self->connections addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}

- (void)removeAllDVDownloadObservers {
    for (id observer in self->connections) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
    [self->connections removeAllObjects];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    ULog(@"Error in registration. Error: %@", [err localizedDescription]);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
