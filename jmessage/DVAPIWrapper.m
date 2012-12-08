//
//  DVAPIWrapper.m
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "DVAPIWrapper.h"
#import "DVDownloader.h"
#import "DVConstants.h"
#import "DVTextMessage.h"

@interface DVAPIWrapper()
@property NSMutableArray *connections;
@end

@implementation DVAPIWrapper
@synthesize connections;

- (void) getAllMessagesAndCallBlock:(void (^)(NSError *,NSArray *))block {
    self->callbackBlock = block;
    
    NSString *urlString = [NSString stringWithFormat:@"%@/message/all", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];

    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    NSLog(@"Get to '%@'", urlString);
    
    [self.connections addObject:downloader];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedGettingMessages:) name:@"downloadDone" object:downloader];
    
    [downloader.connection start]; // setup to have to start manually
}

- (void) finishedGettingMessages: (NSNotification *) notification {
    DVDownloader *downloader = [notification object];
    
    if (notification.userInfo) {
        NSError *err = [notification.userInfo objectForKey:@"error"];
        self->callbackBlock(err, nil);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
        NSLog(@"Received JSON response: %@", jsonString);
        NSArray *messages = [DVTextMessage textMessageArrayFromJSON:jsonString];
        self->callbackBlock(nil, messages);
        NSLog(@"Contained %d messages.", [messages count]);
    }
    
    [self.connections removeObject:downloader];
}

@end
