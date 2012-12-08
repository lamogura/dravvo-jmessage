//
//  DVAPIWrapper.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVAPIWrapper : NSObject {
    void (^callbackBlock)(NSError *, NSArray *);
}

- (void) getAllMessagesAndCallBlock:(void (^)(NSError *, NSArray *))block;
- (void) finishedGettingMessages: (NSNotification *) notification;

@end
