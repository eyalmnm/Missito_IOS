//
//  SignalProto.m
//  Missito
//
//  Created by Alex Gridnev on 3/2/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

#import "SignalProto.h"
#import "Missito-Swift.h"
#import "DecryptionCallback.h"

#include "store/SignalStore.m"

@implementation SignalProto {
    signal_context *global_context;
    session_builder *builder;
    signal_protocol_store_context *store_context;       // alice_store
    uint32_t registration_id;
    NSMutableDictionary *ciphers;           // uid_deviceId -> session_cipher*
//    session_pre_key *last_resort_key;
//    session_signed_pre_key *signed_pre_key;
//    signal_protocol_key_helper_pre_key_list_node *pre_keys_head;
    NSString *userId;
    int signed_pre_key_id;
}

- (instancetype)initForUserId: (NSString *)uid {
     if (self = [super init]) {
         signed_pre_key_id = 1;
         userId = [self removePlusFromNumber:uid];
//         [self setupProto];
         ciphers = [[NSMutableDictionary alloc] init];
         return self;
     } else {
         return nil;
     }
}

- (UInt32)registrationId {
    return registration_id;
}

- (NSString *)identityPublicKey {
    ratchet_identity_key_pair *keyPair;
    signal_protocol_identity_get_key_pair(store_context, &keyPair);
    ec_public_key *public_key = ratchet_identity_key_pair_get_public(keyPair);
    return [self publicKeyToBase64:public_key];
}

- (NSString *)signedPreKeyPublicKey {
    session_signed_pre_key *signed_pre_key;
    // TODO: check return value
    signal_protocol_signed_pre_key_load_key(store_context, &signed_pre_key, signed_pre_key_id);
    ec_key_pair *key_pair = session_signed_pre_key_get_key_pair(signed_pre_key);
    ec_public_key *public_key = ec_key_pair_get_public(key_pair);
    return [self publicKeyToBase64:public_key];
}

- (NSString *)signedPreKeySignature {
    session_signed_pre_key *signed_pre_key;
    // TODO: check return value
    signal_protocol_signed_pre_key_load_key(store_context, &signed_pre_key, signed_pre_key_id);
    NSData *nsdata = [NSData dataWithBytes:session_signed_pre_key_get_signature(signed_pre_key)
                                    length:session_signed_pre_key_get_signature_len(signed_pre_key)];
    return [nsdata base64EncodedStringWithOptions:0];
}

- (UInt32)signedPreKeyId {
    return signed_pre_key_id;
}

- (NSArray<NSString *> *)getOtpKeys:(int) startId {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSArray<PreKeyData *>* pkdArr = [RealmDbHelper getPreKeyArrayWithStartId:startId count:100];
    
    for (PreKeyData *pkd in pkdArr) {
        session_pre_key *pre_key;
        // TODO: check return value, check no gaps
        session_pre_key_deserialize(&pre_key, [pkd.keyRecord bytes], [pkd.keyRecord length], global_context);
        ec_key_pair *key_pair = session_pre_key_get_key_pair(pre_key);
        ec_public_key *public_key = ec_key_pair_get_public(key_pair);
        [array addObject:[self publicKeyToBase64:public_key]];
    }

    return array;
}

- (NSString *)publicKeyToBase64: (ec_public_key *)publicKey {
    signal_buffer *buffer;
    int r = ec_public_key_serialize(&buffer, publicKey);
    NSLog(@"ec_public_key_serialize r=%d", r);
    if (r != 0) {
        return nil;
    }
    NSData *nsdata = [NSData dataWithBytes:signal_buffer_data(buffer) length:signal_buffer_len(buffer)];
    signal_buffer_free(buffer);
    return [nsdata base64EncodedStringWithOptions:0];
}


- (void)setup {
    
    int result = signal_context_create(&global_context, 0);
    NSLog(@"signal_context_create ret=%d", result);
    
    signal_context_set_log_function(global_context, test_log);
    
    setup_test_crypto_provider(global_context);
    result = signal_context_set_locking_functions(global_context, test_lock, test_unlock);
    
    setup_realm_store_context(&store_context, global_context);
    
    if (signal_protocol_identity_get_local_registration_id(store_context, &registration_id) != 0) {
        [self doInitialSetup];
    }

}

- (void)doInitialSetup {
    ratchet_identity_key_pair *identity_key_pair;
    session_signed_pre_key *signed_pre_key;
    
    signal_protocol_key_helper_generate_identity_key_pair(&identity_key_pair, global_context);
    signal_protocol_key_helper_generate_registration_id(&registration_id, 0, global_context);
    
    [self storeLocalIdentity:identity_key_pair];
    [RealmDbHelper saveRegistrationIdData:[[RegistrationIdData alloc] initWithRegistrationId:registration_id]];
    
    long long timestamp = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    signal_protocol_key_helper_generate_signed_pre_key(&signed_pre_key, identity_key_pair, signed_pre_key_id, timestamp, global_context);

    /* Store signed pre key in the signed pre key store. */
    signal_protocol_signed_pre_key_store_key(store_context, signed_pre_key);

    [RealmDbHelper saveNextOTPKIdData:[[NextOTPKIdData alloc] initWithNextId:1]];
    [self addPreKeys];
    
    //    signal_protocol_key_helper_generate_last_resort_pre_key(&last_resort_key, global_context);
}

- (void)addPreKeys {
    NextOTPKIdData *noid = [RealmDbHelper getNextOTPKIdData];
    int otpk_start_id = noid == nil ? 1 : (int)noid.nextId;
    
    signal_protocol_key_helper_pre_key_list_node *pre_keys_head;
    signal_protocol_key_helper_generate_pre_keys(&pre_keys_head, otpk_start_id, 100, global_context);
    
    [RealmDbHelper saveNextOTPKIdData:[[NextOTPKIdData alloc] initWithNextId:otpk_start_id + 100]];

    /* Store pre keys in the pre key store. */
    signal_protocol_key_helper_pre_key_list_node *cur_node = pre_keys_head;
    
    do {
        session_pre_key *pre_key = signal_protocol_key_helper_key_list_element(cur_node);
        // Save prekey record to store
        int r = signal_protocol_pre_key_store_key(store_context, pre_key);
        int id = session_pre_key_get_id(pre_key);
        NSLog(@"store pre_key: %d r=%d", id, r);
        cur_node = signal_protocol_key_helper_key_list_next(cur_node);
    } while (cur_node != NULL);
    [DefaultsHelper saveReportKeysFlag:YES];
}

- (void)storeLocalIdentity:(ratchet_identity_key_pair *)keyPair {
    ec_public_key *publicKey = ratchet_identity_key_pair_get_public(keyPair);
    ec_private_key *privateKey = ratchet_identity_key_pair_get_private(keyPair);
    signal_buffer *publicKeyBuffer;
    signal_buffer *privateKeyBuffer;
    ec_public_key_serialize(&publicKeyBuffer, publicKey);
    ec_private_key_serialize(&privateKeyBuffer, privateKey);
    NSData *publicKeyData = [NSData dataWithBytes:signal_buffer_data(publicKeyBuffer) length:signal_buffer_len(publicKeyBuffer)];
    NSData *privateKeyData = [NSData dataWithBytes:signal_buffer_data(privateKeyBuffer) length:signal_buffer_len(privateKeyBuffer)];
    
    LocalIdentityData *lid = [[LocalIdentityData alloc] initWithPublicKey:publicKeyData privateKey:privateKeyData];
    
    [RealmDbHelper saveLocalIdentityData:lid];
    
    signal_buffer_free(publicKeyBuffer);
    signal_buffer_free(privateKeyBuffer);
}

- (int)buildSessionWithPreKey: (session_pre_key_bundle *)preKeyBundle address: (signal_protocol_address *)address {
    /* Instantiate a session_builder for a recipient address. */
//    signal_protocol_address address = {
//        "+14159998888", 12, 1
//    };
    
    int r = session_builder_create(&builder, store_context, address, global_context);
    
    NSLog(@"session_builder_create r=%d", r);
    if (r != SG_SUCCESS) {
        return r;
    }

    session_pre_key_bundle *retrieved_pre_key = preKeyBundle;
    
    /* Build a session with a pre key retrieved from the server. */
    r = session_builder_process_pre_key_bundle(builder, retrieved_pre_key);
    NSLog(@"session_builder_process_pre_key_bundle r=%d", r);
    return r;
}

- (int)buildSessionWithData: (NewSessionData *)data uid: (NSString *)uid deviceId: (int)deviceId {
    uid = [self removePlusFromNumber:uid];
    session_pre_key_bundle *pre_key_bundle = [self createPreKeyBundleFrom:data];
    signal_protocol_address *address = [self createAddressForUID:uid deviceId: deviceId];
    return [self buildSessionWithPreKey:pre_key_bundle address:address];
}

- (signal_protocol_address *)createAddressForUID: (NSString *)uid deviceId: (int)deviceId {
    uid = [self removePlusFromNumber:uid];
    char *uidp = malloc(uid.length + 1);
    strcpy(uidp, [uid UTF8String]);
    signal_protocol_address *address = malloc(sizeof(signal_protocol_address));
    address->name = uidp;
    address->name_len = strlen(uidp);
    address->device_id = deviceId;
    return address;
}

- (void)freeAddress: (signal_protocol_address *)address {
//    free(address.name);
}

- (session_pre_key_bundle *)createPreKeyBundleFrom: (NewSessionData *)newSessionData {

    ec_public_key *otpk_public_key = 0;
    NSData *otpkPublicKeyData = [[NSData alloc] initWithBase64EncodedString:newSessionData.otpk.key options:0];
    curve_decode_point(&otpk_public_key, otpkPublicKeyData.bytes, otpkPublicKeyData.length, global_context);
    
    ec_public_key *spk_public_key = 0;
    NSData *spkPublicKeyData = [[NSData alloc] initWithBase64EncodedString:newSessionData.signedPreKey.key options:0];
    curve_decode_point(&spk_public_key, spkPublicKeyData.bytes, spkPublicKeyData.length, global_context);
    
    NSData *spkSignatureData = [[NSData alloc] initWithBase64EncodedString:newSessionData.signedPreKey.keySignature options:0];
    
    ec_public_key *identity_public_key = 0;
    NSData *identityPublicKeyData = [[NSData alloc] initWithBase64EncodedString:newSessionData.identity.identityPublicKey options:0];
    curve_decode_point(&identity_public_key, identityPublicKeyData.bytes, identityPublicKeyData.length, global_context);
    
    session_pre_key_bundle *pre_key_bundle = 0;
    int result = session_pre_key_bundle_create(&pre_key_bundle,
                                           newSessionData.identity.registrationId,
                                           1, /* device ID */
                                           newSessionData.otpk.keyId, /* pre key ID */
                                           otpk_public_key,
                                           newSessionData.signedPreKey.keyId, /* signed pre key ID */
                                           spk_public_key,
                                           spkSignatureData.bytes,
                                           spkSignatureData.length,
                                           identity_public_key);
    if (result != 0) {
        return nil;
    }
    return pre_key_bundle;
}

- (BOOL)sessionExistsForUID: (NSString *)uid deviceId: (int)deviceId {
    uid = [self removePlusFromNumber:uid];
    signal_protocol_address *address = [self createAddressForUID:uid deviceId: deviceId];
    int result = signal_protocol_session_contains_session(store_context, address);
    [self freeAddress: address];
    return result == 1;
}

- (session_cipher *)getCipherForAddress:(signal_protocol_address *)address {
    NSString *name = [NSString stringWithUTF8String:address->name];
    NSString *key = [RemoteIdentityData calcIdWithName:name deviceId:address->device_id];
    NSValue *cipherVal = ciphers[key];
    session_cipher *cipher = cipherVal.pointerValue;
    if (cipher == NULL) {
        session_cipher_create(&cipher, store_context, address, global_context);
//        ciphers[uid] = (__bridge id _Nullable)(cipher);
        ciphers[key] = [NSValue valueWithPointer:cipher];
        session_cipher_set_decryption_callback(cipher, onDecrypt);
    }
    return cipher;
}

- (ciphertext_message *)encryptMessage: (const uint8_t *)message messageLen: (size_t)len to: (signal_protocol_address *)address {

    session_cipher *cipher = [self getCipherForAddress:address];
    if (cipher == NULL) {
        NSLog(@"encryptMessage: Can't create cipher");
        return NULL;
    }
    ciphertext_message *encrypted_message;
    int r = session_cipher_encrypt(cipher, message, len, &encrypted_message);
    
    NSLog(@"session_cipher_encrypt r=%d", r);
    
    return encrypted_message;
    
//    /* Get the serialized content and deliver it */
//    signal_buffer *serialized = ciphertext_message_get_serialized(encrypted_message);
//    
//    return serialized;
//
//    deliver(signal_buffer_data(serialized), signal_buffer_len(serialized));
    
}

- (NSString *)removePlusFromNumber: (NSString *)phone {
    return [phone hasPrefix:@"+"] ? [phone substringFromIndex:1] : phone;
}

- (BrokerMessage *)encryptMessage: (NSString *)message destUid: (NSString *)uid destDeviceId: (int)deviceId {
    // removePlusFrom phone
    uid = [self removePlusFromNumber:uid];
    signal_protocol_address *address = [self createAddressForUID:uid deviceId: deviceId];
    ciphertext_message *encrypted_message = [self encryptMessage:(uint8_t *)message.UTF8String messageLen:strlen(message.UTF8String) to:address];
    signal_buffer *outgoing_serialized = ciphertext_message_get_serialized(encrypted_message);

    uint8_t *msg_data = signal_buffer_data(outgoing_serialized);
    size_t msg_len = signal_buffer_len(outgoing_serialized);
    NSData *messageData = [NSData dataWithBytes:msg_data length:msg_len];
    [self freeAddress: address];
    NSString *encryptedStr = [messageData base64EncodedStringWithOptions:0];
    
    int type = ciphertext_message_get_type(encrypted_message);
    NSLog(@"encrypted: %d %@", type, encryptedStr);

//#define CIPHERTEXT_SIGNAL_TYPE                 2
//#define CIPHERTEXT_PREKEY_TYPE                 3
//#define CIPHERTEXT_SENDERKEY_TYPE              4
//#define CIPHERTEXT_SENDERKEY_DISTRIBUTION_TYPE 5
    
    BrokerMessage *bm = [[BrokerMessage alloc] initWithMessageType:(type == CIPHERTEXT_PREKEY_TYPE ? @"init" : @"next") body:encryptedStr senderUid:userId];
    //BrokerMessage.init(messageType: isPreKey ? "pre_key" : "common", body: message, senderUid: uid)
    
    return bm;
}

int onDecrypt(session_cipher *cipher, signal_buffer *plaintext, void *decrypt_context) {
    DecryptionCallback *callbackObj = (__bridge_transfer id) decrypt_context;
    NSData *data = [SignalProto getDataFromSignalBuffer:plaintext];
    [callbackObj onDecrypt: data];
    return SG_SUCCESS;
}

+ (NSData *)getDataFromSignalBuffer: (signal_buffer *)buffer {
    uint8_t *data = signal_buffer_data(buffer);
    size_t len = signal_buffer_len(buffer);
    
    NSLog(@"%s", data);
    return [NSData dataWithBytes:data length:len];
}

- (BOOL)decryptPreKeyMessage: (NSData *)message from: (signal_protocol_address *)address decryptionCallback: (void (^)(NSData *))callback {
    
    DecryptionCallback *callbackObj = [[DecryptionCallback alloc] initWithBlock:callback];
    void *decrypt_context = (__bridge_retained void *) callbackObj;
    
    pre_key_signal_message *incoming_message = 0;
    int result = pre_key_signal_message_deserialize(&incoming_message,
                                                [message bytes],
                                                [message length], global_context);
    
    NSLog(@"result=%d", result);
    
    session_cipher *cipher = [self getCipherForAddress:address];
    if (cipher == NULL) {
        NSLog(@"decryptPreKeyMessage: Can't create cipher");
        return false;
    }

    // Decrypt
    signal_buffer *plaintext = 0;
    result = session_cipher_decrypt_pre_key_signal_message(cipher, incoming_message, decrypt_context, &plaintext);
    if (result != SG_SUCCESS) {
        NSLog(@"session_cipher_decrypt_pre_key_signal_message failed r=%d", result);
        return false;
    }
    
    signal_buffer_free(plaintext);
    return true;
}

- (BOOL)decryptMessage: (NSData *)message from: (signal_protocol_address *)address decryptionCallback: (void (^)(NSData *))callback {
    
    DecryptionCallback *callbackObj = [[DecryptionCallback alloc] initWithBlock:callback];
    void *decrypt_context = (__bridge_retained void *) callbackObj;

    session_cipher *cipher = [self getCipherForAddress:address];
    if (cipher == NULL) {
        NSLog(@"decryptMessage: Can't create cipher");
        return false;
    }
    
    // Decrypt
    signal_message *incoming_message = 0;
    int result = signal_message_deserialize(&incoming_message,
                                            [message bytes],
                                            [message length], global_context);
    NSLog(@"signal_message_deserialize r=%d", result);
    if (result != 0) {
        return false;
    }
    signal_buffer *plaintext = 0;
    result = session_cipher_decrypt_signal_message(cipher, incoming_message, decrypt_context, &plaintext);
    NSLog(@"result=%d", result);
    if (result != 0) {
        return false;
    }
    
    signal_buffer_free(plaintext);
    return true;
}

- (BOOL)decryptIncomingMessage: (IncomingMessage *)incomingMessage decryptionCallback: (void (^)(NSData *))callback {
    BOOL result;
    NSData *data = [[NSData alloc] initWithBase64EncodedString:incomingMessage.msg options:0];
    signal_protocol_address *address = [self createAddressForUID:[self removePlusFromNumber: incomingMessage.senderUid] deviceId:(int)incomingMessage.senderDeviceId];
    
    NSLog(@"decrypt %@", incomingMessage.msg);
    
    if ([incomingMessage.msgType isEqual:@"init"]) {
        result = [self decryptPreKeyMessage:data from:address decryptionCallback: callback];
    } else {
        result = [self decryptMessage:data from:address decryptionCallback: callback];
    }
    [self freeAddress: address];
    return result;
}

//+ (void)test {
//    
//    // Setup addresses
//    
//    static signal_protocol_address alice_address = {
//        "+14151111111", 12, 1
//    };
//    
//    static signal_protocol_address bob_address = {
//        "+14152222222", 12, 1
//    };
//    
//    
//    
//    // Alice
//    
//    signal_context *alice_global_context;
//    
//    int result = signal_context_create(&alice_global_context, 0);
//    NSLog(@"signal_context_create ret=%d", result);
//    setup_test_crypto_provider(alice_global_context);
//    result = signal_context_set_locking_functions(alice_global_context, test_lock, test_unlock);
//    signal_context_set_log_function(alice_global_context, test_log);
//
//    
//    ratchet_identity_key_pair *alice_identity_key_pair;
//    uint32_t alice_registration_id;
//    signal_protocol_key_helper_pre_key_list_node *alice_pre_keys_head;
//    session_pre_key *alice_last_resort_key;
//    session_signed_pre_key *alice_signed_pre_key;
//    
//    signal_protocol_key_helper_generate_identity_key_pair(&alice_identity_key_pair, alice_global_context);
//    signal_protocol_key_helper_generate_registration_id(&alice_registration_id, 0, alice_global_context);
//    signal_protocol_key_helper_generate_pre_keys(&alice_pre_keys_head, 0, 100, alice_global_context);
//    signal_protocol_key_helper_generate_last_resort_pre_key(&alice_last_resort_key, alice_global_context);
//    
//    /* Create Alice' data store */
//    signal_protocol_store_context *alice_store = 0;
//    setup_test_store_context(&alice_store, alice_global_context, alice_identity_key_pair, alice_registration_id);
//
//    result = signal_protocol_identity_get_key_pair(alice_store, &alice_identity_key_pair);
//    
//    long long timestamp = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
//    signal_protocol_key_helper_generate_signed_pre_key(&alice_signed_pre_key, alice_identity_key_pair, 5, timestamp, alice_global_context);
//
////    session_builder *alice_session_builder;
////    signal_protocol_store_context *alice_session_store;
//    
//    // Bob
//    
//    signal_context *bob_global_context;
//    
//    result = signal_context_create(&bob_global_context, 0);
//    NSLog(@"signal_context_create ret=%d", result);
//    setup_test_crypto_provider(bob_global_context);
//    result = signal_context_set_locking_functions(bob_global_context, test_lock, test_unlock);
//    signal_context_set_log_function(bob_global_context, test_log);
//    
//    ratchet_identity_key_pair *bob_identity_key_pair;
//    uint32_t bob_registration_id;
//    signal_protocol_key_helper_pre_key_list_node *bob_pre_keys_head;
//    session_pre_key *bob_last_resort_key;
//    session_signed_pre_key *bob_signed_pre_key;
//    
//    signal_protocol_key_helper_generate_identity_key_pair(&bob_identity_key_pair, bob_global_context);
//    signal_protocol_key_helper_generate_registration_id(&bob_registration_id, 0, bob_global_context);
//    signal_protocol_key_helper_generate_pre_keys(&bob_pre_keys_head, 0, 100, bob_global_context);
//    signal_protocol_key_helper_generate_last_resort_pre_key(&bob_last_resort_key, bob_global_context);
//
//    /* Create Bob's data store */
//    signal_protocol_store_context *bob_store = 0;
//    setup_test_store_context(&bob_store, bob_global_context, bob_identity_key_pair, bob_registration_id);
//    
//    result = signal_protocol_identity_get_key_pair(bob_store, &bob_identity_key_pair);
//
//    signal_protocol_key_helper_generate_signed_pre_key(&bob_signed_pre_key, bob_identity_key_pair, 5, timestamp, bob_global_context);
//
//
//    // Save prekey record to store
//    session_pre_key *bob_pre_key = signal_protocol_key_helper_key_list_element(bob_pre_keys_head);
//    ec_key_pair *bob_pre_key_pair = session_pre_key_get_key_pair(bob_pre_key);
//    int bob_pre_key_id = session_pre_key_get_id(bob_pre_key);
//    result = signal_protocol_pre_key_store_key(bob_store, bob_pre_key);
//    
//    // Save signed prekey
//    result = signal_protocol_signed_pre_key_store_key(bob_store, bob_signed_pre_key);
//    
//    // Alice - Server - get Keys to initiate session with Bob
//    
//    // Server
//    
//
//    ec_key_pair *bob_signed_pre_key_pair = session_signed_pre_key_get_key_pair(bob_signed_pre_key);
//    const uint8_t *bob_signed_pre_key_signature = session_signed_pre_key_get_signature(bob_signed_pre_key);
//    size_t bob_signed_pre_key_signature_len = session_signed_pre_key_get_signature_len(bob_signed_pre_key);
//
//    // Server creates Bob's pre key bundle
//    session_pre_key_bundle *bob_pre_key_bundle = 0;
//    result = session_pre_key_bundle_create(&bob_pre_key_bundle,
//                                                   bob_registration_id,
//                                                   1, /* device ID */
//                                                   bob_pre_key_id, /* pre key ID */
//                                                   ec_key_pair_get_public(bob_pre_key_pair),
//                                           session_signed_pre_key_get_id(bob_signed_pre_key)
//, /* signed pre key ID */
//                                                   ec_key_pair_get_public(bob_signed_pre_key_pair),
//                                                   bob_signed_pre_key_signature,
//                                                   bob_signed_pre_key_signature_len,
//                                                   ratchet_identity_key_pair_get_public(bob_identity_key_pair));
//    NSLog(@"result=%d", result);
//    
//    
//    // Alice receives Bob's pre key bundle and processes it
//    
//    // First - Alice have to create session to communicate with Bob
//    
//    /* Create Alice's data store and session builder */
//    session_builder *alice_session_builder = 0;
//    result = session_builder_create(&alice_session_builder, alice_store, &bob_address, alice_global_context);
//
//    
//    result = session_builder_process_pre_key_bundle(alice_session_builder, bob_pre_key_bundle);
//    NSLog(@"result=%d", result);
//    
//    /* Encrypt an outgoing message to send to Bob */
//
//    // Prepare cipher
//    session_cipher *alice_session_cipher = 0;
//    result = session_cipher_create(&alice_session_cipher, alice_store, &bob_address, alice_global_context);
//
//    // Encrypt message
//    static const char original_message[] = "L'homme est condamné à être libre";
//    size_t original_message_len = sizeof(original_message);
//    ciphertext_message *outgoing_message = 0;
//    result = session_cipher_encrypt(alice_session_cipher, (uint8_t *)original_message, original_message_len, &outgoing_message);
//    
////    ck_assert_int_eq(ciphertext_message_get_type(outgoing_message), CIPHERTEXT_PREKEY_TYPE);
//    
//    signal_buffer *outgoing_serialized = ciphertext_message_get_serialized(outgoing_message);
//    
//    
//    // Deliver outgoing_serialized to Bob
//    
//    
//    // Bob - parse and decrypt received message
//
//    // Deserialize - NOTE: Bob must know the type of the message - CIPHERTEXT_PREKEY_TYPE
//    pre_key_signal_message *incoming_message = 0;
//    result = pre_key_signal_message_deserialize(&incoming_message,
//                                                signal_buffer_data(outgoing_serialized),
//                                                signal_buffer_len(outgoing_serialized), bob_global_context);
//
//    NSLog(@"result=%d", result);
//    
//    /* Create Bob's session cipher and decrypt the message from Alice */
//    session_cipher *bob_session_cipher = 0;
//    result = session_cipher_create(&bob_session_cipher, bob_store, &alice_address, bob_global_context);
//    
//    // Decrypt
//    signal_buffer *plaintext = 0;
//    result = session_cipher_decrypt_pre_key_signal_message(bob_session_cipher, incoming_message, NULL, &plaintext);
//    NSLog(@"result=%d", result);
//    
//    uint8_t *plaintext_data = signal_buffer_data(plaintext);
//    size_t plaintext_len = signal_buffer_len(plaintext);
//    
//    NSLog(@"%s", plaintext_data);
//    
//    
//    /* Have Bob send a reply to Alice */
//    ciphertext_message *bob_outgoing_message = 0;
//    result = session_cipher_encrypt(bob_session_cipher, (uint8_t *)original_message, original_message_len, &bob_outgoing_message);
//    
//    signal_buffer *bob_outgoing_serialized = ciphertext_message_get_serialized(bob_outgoing_message);
//    
//    /* Verify that Alice can decrypt it */
//    signal_message *alice_incoming_message = 0;
//    result = signal_message_deserialize(&alice_incoming_message,
//                                                signal_buffer_data(bob_outgoing_serialized),
//                                                signal_buffer_len(bob_outgoing_serialized), alice_global_context);
//    
//    signal_buffer *alice_plaintext = 0;
//    result = session_cipher_decrypt_signal_message(alice_session_cipher, alice_incoming_message, 0, &alice_plaintext);
//    
//    uint8_t *alice_plaintext_data = signal_buffer_data(alice_plaintext);
//    size_t alice_plaintext_len = signal_buffer_len(alice_plaintext);
//    
//    NSLog(@"%s", alice_plaintext_data);
//    
//    
//    // Alice sends again
//    
//    ciphertext_message *alice_message = 0;
//    result = session_cipher_encrypt(alice_session_cipher, (uint8_t *)original_message, original_message_len, &alice_message);
//
//    ciphertext_message *alice_outgoing_message = 0;
//    result = session_cipher_encrypt(alice_session_cipher, (uint8_t *)original_message, original_message_len, &alice_outgoing_message);
//    
//    signal_buffer *alice_outgoing_serialized = ciphertext_message_get_serialized(alice_outgoing_message);
//
//    
//    // Bob decrypt again
//    
//    signal_message *bob_incoming_message = 0;
//    result = signal_message_deserialize(&bob_incoming_message,
//                                        signal_buffer_data(alice_outgoing_serialized),
//                                        signal_buffer_len(alice_outgoing_serialized), bob_global_context);
//    
//    signal_buffer *bob_plaintext = 0;
//    result = session_cipher_decrypt_signal_message(bob_session_cipher, bob_incoming_message, 0, &bob_plaintext);
//    
//    uint8_t *bob_plaintext_data = signal_buffer_data(bob_plaintext);
//    size_t bob_plaintext_len = signal_buffer_len(bob_plaintext);
//    
//    NSLog(@"%s", bob_plaintext_data);
//
//    // TODO: cleanup (free memory)
//}

@end

