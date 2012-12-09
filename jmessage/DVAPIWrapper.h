//
//  DVAPIWrapper.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVTextMessage.h"

@interface DVAPIWrapper : NSObject

- (id) init;

- (void) getAllMessagesAndCallBlock:(void (^)(NSError *, NSArray *))block;
- (void) sendMessage:(DVTextMessage *)msg AndCallBlock:(void (^)(NSError *, DVTextMessage *msg))block;

@end
