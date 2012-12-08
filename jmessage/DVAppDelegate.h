//
//  DVAppDelegate.h
//  iostest
//
//  Created by mogura on 12/2/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JASidePanelController.h"

@class DVRootViewController;

@interface DVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) JASidePanelController *viewController;

@end
