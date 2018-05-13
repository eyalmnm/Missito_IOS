//
//  DecryptionCallback.h
//  Missito
//
//  Created by Alex Gridnev on 12/27/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DecryptionCallback : NSObject

- (instancetype)initWithBlock:(void (^)(NSData *))callbackBlock;
- (void)onDecrypt: (NSData *)plaintext;

@end
