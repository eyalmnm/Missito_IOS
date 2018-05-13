//
//  DecryptionCallback.m
//  Missito
//
//  Created by Alex Gridnev on 12/27/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

#import "DecryptionCallback.h"

@implementation DecryptionCallback {
    void(^callback)(NSData *);
}

- (instancetype)initWithBlock:(void (^)(NSData *))callbackBlock
{
    self = [super init];
    if (self) {
        callback = callbackBlock;
    }
    return self;
}

- (void)onDecrypt: (NSData *)plaintext {
    callback(plaintext);
}

@end
