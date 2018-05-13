//
//  SignalProto.h
//  Missito
//
//  Created by Alex Gridnev on 3/2/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "signal_protocol_types.h"
#include "signal_protocol.h"
#include "session_builder.h"
#include "session_cipher.h"
#include "protocol.h"
#include "key_helper.h"
#include "utlist.h"


@class NewSessionData;
@class BrokerMessage;
@class IncomingMessage;

@interface SignalProto : NSObject

@property (nonatomic, readonly, getter = identityPublicKey) NSString *identityPublicKey;
@property (nonatomic, readonly, getter = registrationId) UInt32 registrationId;

@property (nonatomic, readonly, getter = signedPreKeyPublicKey) NSString *signedPreKeyPublicKey;
@property (nonatomic, readonly, getter = signedPreKeySignature) NSString *signedPreKeySignature;
@property (nonatomic, readonly, getter = signedPreKeyId) UInt32 signedPreKeyId;


- (instancetype)initForUserId: (NSString *)uid;
- (void)setup;
- (BOOL)sessionExistsForUID: (NSString *)uid deviceId: (int)deviceId;
- (int)buildSessionWithData: (NewSessionData *)data uid: (NSString *)uid deviceId: (int)deviceId;
- (ciphertext_message *)encryptMessage: (const uint8_t *)message messageLen: (size_t)len to: (signal_protocol_address *)address;
- (BrokerMessage *)encryptMessage: (NSString *)message destUid: (NSString *)uid destDeviceId: (int)deviceId;
- (BOOL)decryptIncomingMessage: (IncomingMessage *)incomingMessage decryptionCallback: (void (^)(NSData *))callback;
- (NSArray<NSString *> *)getOtpKeys:(int) startId;


@end
