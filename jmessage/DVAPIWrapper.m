//
//  DVAPIWrapper.m
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "SBJson.h"

#import "DVAPIWrapper.h"
#import "DVDownloader.h"
#import "DVConstants.h"
#import "DVTextMessage.h"
#import "DVMacros.h"

@interface DVAPIWrapper()  {
    NSMutableSet *connections; // downloader connections live
    NSMutableSet *observers; // notification observers live
    
    // callbacks user functions for api actions
    void (^getMessagesCallback)(NSError *, NSArray *);
    void (^sendMessageCallback)(NSError *, DVTextMessage *);
}

@end

@implementation DVAPIWrapper

- (id) init {
    self = [super init];
    if (self) {
        self->connections = [[NSMutableSet alloc] init];
        self->observers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void) getAllMessagesAndCallBlock:(void (^)(NSError *,NSArray *))block {
    self->getMessagesCallback = block;
    
    NSString *urlString = [NSString stringWithFormat:@"%@/message/all", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    DLog(@"Get to '%@'", urlString);
    
    [self->connections addObject:downloader];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:DVDownloaderDidFinishDownloading object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        if (notification.userInfo) {
            NSError *err = [notification.userInfo objectForKey:@"error"];
            self->getMessagesCallback(err, nil);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"Received JSON response: %@", jsonString);
            NSArray *messages = [DVTextMessage textMessageArrayFromJSON:jsonString];
            DLog(@"Contained %d messages.", [messages count]);
            self->getMessagesCallback(nil, messages);
        }
        
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}
- (void) sendMessage:(DVTextMessage *)msg AndCallBlock:(void (^)(NSError *, DVTextMessage *msg))block {
    self->sendMessageCallback = block;
    
    NSString *urlString = [NSString stringWithFormat:@"%@/message/new", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *dataString = [NSString stringWithFormat:@"username=%@&message_text=%@", msg.username, msg.messageText];
    NSString *dataLength = [NSString stringWithFormat:@"%d", [dataString length]];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [req setHTTPMethod:@"POST"];
    [req setValue:dataLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:data];
    
    DLog(@"POST to '%@' with body '%@'", urlString, dataString);
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    [self->connections addObject:downloader];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:DVDownloaderDidFinishDownloading object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        if (notification.userInfo) {
            NSError *error = [notification.userInfo objectForKey:@"error"];
            self->sendMessageCallback(error, nil);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"Received JSON response: %@", jsonString);
            NSDictionary *resp = [jsonString JSONValue];
            
            if ([resp valueForKey:@"error"] != nil) {
                NSString *errorString = [[resp objectForKey:@"error"] objectForKey:@"message"];
                DLog(@"Contained an error: %@", errorString);
                NSError *error = [NSError errorWithDomain:@"DVAPIWrapperErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorString, @"")}];
                self->sendMessageCallback(error, nil);
            } else {
                DLog(@"POST message saved successfully.");
                DVTextMessage *msg = [[DVTextMessage alloc] initWithDictionary:[resp objectForKey:@"saved_message"]];
                self->sendMessageCallback(nil, msg);
            }
        }
        
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}
- (void) dealloc {
    // final chance to remove an observer
    for (id obj in self->observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:obj];
    }
    self->connections = nil;
    self->observers = nil;
}

@end
