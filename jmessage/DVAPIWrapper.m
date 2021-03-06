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
}

@end

@implementation DVAPIWrapper

#pragma mark - API Functions
- (void) getAllMessagesAndCallBlock:(void (^)(NSError *,NSArray *))block {
    NSString *urlString = [NSString stringWithFormat:@"%@/message/all", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    DLog(@"Get to '%@'", urlString);
    
    [self->connections addObject:downloader];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:DVDownloaderDidFinishDownloading object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        if (notification.userInfo) {
            NSError *err = [notification.userInfo objectForKey:@"error"];
            block(err, nil);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"Received JSON response: %@", jsonString);
            NSArray *messages = [DVTextMessage textMessageArrayFromJSON:jsonString];
            DLog(@"Contained %d messages.", [messages count]);
            block(nil, messages);
        }
        
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}

- (void) sendMessage:(DVTextMessage *)msg AndCallBlock:(void (^)(NSError *, DVTextMessage *msg))block {
    NSString *urlString = [NSString stringWithFormat:@"%@/message/new", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *dataString = [NSString stringWithFormat:@"username=%@&message_text=%@", msg.username, msg.messageText];
    NSString *dataLength = [NSString stringWithFormat:@"%d", [dataString length]];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [req setHTTPMethod:@"POST"];
    [req setValue:dataLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:data];
    
    DLog(@"POST to '%@' with body '%@'", urlString, dataString);
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    [self->connections addObject:downloader];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:DVDownloaderDidFinishDownloading object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        if (notification.userInfo) {
            NSError *error = [notification.userInfo objectForKey:@"error"];
            block(error, nil);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"Received JSON response: %@", jsonString);
            NSDictionary *resp = [jsonString JSONValue];
            
            if ([resp valueForKey:@"error"] != nil) {
                NSString *errorString = [[resp objectForKey:@"error"] objectForKey:@"message"];
                DLog(@"Contained an error: %@", errorString);
                NSError *error = [NSError errorWithDomain:@"DVAPIWrapperErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorString, @"")}];
                block(error, nil);
            } else {
                DLog(@"POST message saved successfully.");
                DVTextMessage *msg = [[DVTextMessage alloc] initWithDictionary:[resp objectForKey:@"saved_message"]];
                block(nil, msg);
            }
        }
        
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}

- (void) deleteMessage:(DVTextMessage *)msg AndCallBlock:(void (^)(NSError *))block {
    NSString *urlString = [NSString stringWithFormat:@"%@/message/%@/delete", kBaseURL, msg.dbID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [req setHTTPMethod:@"DELETE"];

    DLog(@"DELETE to '%@'", urlString);
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    [self->connections addObject:downloader];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:DVDownloaderDidFinishDownloading object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        if (notification.userInfo) {
            NSError *error = [notification.userInfo objectForKey:@"error"];
            block(error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"Received JSON response: %@", jsonString);
            NSDictionary *resp = [jsonString JSONValue];
            
            if ([resp valueForKey:@"error"] != nil) {
                NSString *errorString = [[resp objectForKey:@"error"] objectForKey:@"message"];
                DLog(@"Contained an error: %@", errorString);
                NSError *error = [NSError errorWithDomain:@"DVAPIWrapperErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorString, @"")}];
                block(error);
            } else {
                DLog(@"Deleted message successfully.");
                block(nil);
            }
        }
        
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}

#pragma mark - Lifetime
- (id) init {
    self = [super init];
    if (self) {
        self->connections = [[NSMutableSet alloc] init];
        self->observers = [[NSMutableSet alloc] init];
    }
    return self;
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
