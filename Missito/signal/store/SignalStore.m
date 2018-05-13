//
//  SignalTest.m
//  Missito
//
//  Created by Alex Gridnev on 5/16/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SignalStore.h"
#include <openssl/hmac.h>
#include <openssl/rand.h>
#include <openssl/ossl_typ.h>
#include <pthread.h>
#include "uthash.h"
#include "signal_protocol.h"

#import "Missito-Swift.h"

pthread_mutex_t global_mutex;
pthread_mutexattr_t global_mutex_attr;

void test_lock(void *user_data)
{
    pthread_mutex_lock(&global_mutex);
}

void test_unlock(void *user_data)
{
    pthread_mutex_unlock(&global_mutex);
}

/*
 * This is an implementation of Jenkin's "One-at-a-Time" hash.
 *
 * http://www.burtleburtle.net/bob/hash/doobs.html
 *
 * It is used to simplify using our new string recipient IDs
 * as part of our keys without having to significantly modify the
 * testing-only implementations of our data stores.
 */
int64_t jenkins_hash(const char *key, size_t len)
{
    uint64_t hash, i;
    for(hash = i = 0; i < len; ++i) {
        hash += key[i];
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    return hash;
}

int test_random_generator(uint8_t *data, size_t len, void *user_data)
{
    if(RAND_bytes(data, len)) {
        return 0;
    }
    else {
        return SG_ERR_UNKNOWN;
    }
}

int test_hmac_sha256_init(void **hmac_context, const uint8_t *key, size_t key_len, void *user_data)
{
    HMAC_CTX *ctx = malloc(sizeof(HMAC_CTX));
    if(!ctx) {
        return SG_ERR_NOMEM;
    }
    HMAC_CTX_init(ctx);
    *hmac_context = ctx;
    
    if(HMAC_Init_ex(ctx, key, key_len, EVP_sha256(), 0) != 1) {
        return SG_ERR_UNKNOWN;
    }
    
    return 0;
}

int test_hmac_sha256_update(void *hmac_context, const uint8_t *data, size_t data_len, void *user_data)
{
    HMAC_CTX *ctx = hmac_context;
    int result = HMAC_Update(ctx, data, data_len);
    return (result == 1) ? 0 : -1;
}

int test_hmac_sha256_final(void *hmac_context, signal_buffer **output, void *user_data)
{
    int result = 0;
    unsigned char md[EVP_MAX_MD_SIZE];
    unsigned int len = 0;
    HMAC_CTX *ctx = hmac_context;
    
    if(HMAC_Final(ctx, md, &len) != 1) {
        return SG_ERR_UNKNOWN;
    }
    
    signal_buffer *output_buffer = signal_buffer_create(md, len);
    if(!output_buffer) {
        result = SG_ERR_NOMEM;
        goto complete;
    }
    
    *output = output_buffer;
    
complete:
    return result;
}

void test_hmac_sha256_cleanup(void *hmac_context, void *user_data)
{
    if(hmac_context) {
        HMAC_CTX *ctx = hmac_context;
        HMAC_CTX_cleanup(ctx);
        free(ctx);
    }
}

const EVP_CIPHER *aes_cipher(int cipher, size_t key_len)
{
    if(cipher == SG_CIPHER_AES_CBC_PKCS5) {
        if(key_len == 16) {
            return EVP_aes_128_cbc();
        }
        else if(key_len == 24) {
            return EVP_aes_192_cbc();
        }
        else if(key_len == 32) {
            return EVP_aes_256_cbc();
        }
    }
    else if(cipher == SG_CIPHER_AES_CTR_NOPADDING) {
        if(key_len == 16) {
            return EVP_aes_128_ctr();
        }
        else if(key_len == 24) {
            return EVP_aes_192_ctr();
        }
        else if(key_len == 32) {
            return EVP_aes_256_ctr();
        }
    }
    return 0;
}

int test_sha512_digest_init(void **digest_context, void *user_data)
{
    int result = 0;
    EVP_MD_CTX *ctx;
    
    ctx = EVP_MD_CTX_create();
    if(!ctx) {
        result = SG_ERR_NOMEM;
        goto complete;
    }
    
    result = EVP_DigestInit_ex(ctx, EVP_sha512(), 0);
    if(result == 1) {
        result = SG_SUCCESS;
    }
    else {
        result = SG_ERR_UNKNOWN;
    }
    
complete:
    if(result < 0) {
        if(ctx) {
            EVP_MD_CTX_destroy(ctx);
        }
    }
    else {
        *digest_context = ctx;
    }
    return result;
}


int test_sha512_digest_update(void *digest_context, const uint8_t *data, size_t data_len, void *user_data)
{
    EVP_MD_CTX *ctx = digest_context;
    
    int result = EVP_DigestUpdate(ctx, data, data_len);
    
    return (result == 1) ? SG_SUCCESS : SG_ERR_UNKNOWN;
}

int test_sha512_digest_final(void *digest_context, signal_buffer **output, void *user_data)
{
    int result = 0;
    unsigned char md[EVP_MAX_MD_SIZE];
    unsigned int len = 0;
    EVP_MD_CTX *ctx = digest_context;
    
    result = EVP_DigestFinal_ex(ctx, md, &len);
    if(result == 1) {
        result = SG_SUCCESS;
    }
    else {
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    result = EVP_DigestInit_ex(ctx, EVP_sha512(), 0);
    if(result == 1) {
        result = SG_SUCCESS;
    }
    else {
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    signal_buffer *output_buffer = signal_buffer_create(md, len);
    if(!output_buffer) {
        result = SG_ERR_NOMEM;
        goto complete;
    }
    
    *output = output_buffer;
    
complete:
    return result;
}

void test_sha512_digest_cleanup(void *digest_context, void *user_data)
{
    EVP_MD_CTX *ctx = digest_context;
    EVP_MD_CTX_destroy(ctx);
}

int test_encrypt(signal_buffer **output,
                 int cipher,
                 const uint8_t *key, size_t key_len,
                 const uint8_t *iv, size_t iv_len,
                 const uint8_t *plaintext, size_t plaintext_len,
                 void *user_data)
{
    int result = 0;
    uint8_t *out_buf = 0;
    
    const EVP_CIPHER *evp_cipher = aes_cipher(cipher, key_len);
    if(!evp_cipher) {
        fprintf(stderr, "invalid AES mode or key size: %zu\n", key_len);
        return SG_ERR_UNKNOWN;
    }
    
    if(iv_len != 16) {
        fprintf(stderr, "invalid AES IV size: %zu\n", iv_len);
        return SG_ERR_UNKNOWN;
    }
    
    if(plaintext_len > INT_MAX - EVP_CIPHER_block_size(evp_cipher)) {
        fprintf(stderr, "invalid plaintext length: %zu\n", plaintext_len);
        return SG_ERR_UNKNOWN;
    }
    
    EVP_CIPHER_CTX ctx;
    EVP_CIPHER_CTX_init(&ctx);
    
    result = EVP_EncryptInit_ex(&ctx, evp_cipher, 0, key, iv);
    if(!result) {
        fprintf(stderr, "cannot initialize cipher\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    if(cipher == SG_CIPHER_AES_CTR_NOPADDING) {
        result = EVP_CIPHER_CTX_set_padding(&ctx, 0);
        if(!result) {
            fprintf(stderr, "cannot set padding\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }
    
    out_buf = malloc(sizeof(uint8_t) * (plaintext_len + EVP_CIPHER_block_size(evp_cipher)));
    if(!out_buf) {
        fprintf(stderr, "cannot allocate output buffer\n");
        result = SG_ERR_NOMEM;
        goto complete;
    }
    
    int out_len = 0;
    result = EVP_EncryptUpdate(&ctx,
                               out_buf, &out_len, plaintext, plaintext_len);
    if(!result) {
        fprintf(stderr, "cannot encrypt plaintext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    int final_len = 0;
    result = EVP_EncryptFinal_ex(&ctx, out_buf + out_len, &final_len);
    if(!result) {
        fprintf(stderr, "cannot finish encrypting plaintext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    *output = signal_buffer_create(out_buf, out_len + final_len);
    
complete:
    EVP_CIPHER_CTX_cleanup(&ctx);
    if(out_buf) {
        free(out_buf);
    }
    return result;
}

int test_decrypt(signal_buffer **output,
                 int cipher,
                 const uint8_t *key, size_t key_len,
                 const uint8_t *iv, size_t iv_len,
                 const uint8_t *ciphertext, size_t ciphertext_len,
                 void *user_data)
{
    int result = 0;
    uint8_t *out_buf = 0;
    
    const EVP_CIPHER *evp_cipher = aes_cipher(cipher, key_len);
    if(!evp_cipher) {
        fprintf(stderr, "invalid AES mode or key size: %zu\n", key_len);
        return SG_ERR_INVAL;
    }
    
    if(iv_len != 16) {
        fprintf(stderr, "invalid AES IV size: %zu\n", iv_len);
        return SG_ERR_INVAL;
    }
    
    if(ciphertext_len > INT_MAX - EVP_CIPHER_block_size(evp_cipher)) {
        fprintf(stderr, "invalid ciphertext length: %zu\n", ciphertext_len);
        return SG_ERR_UNKNOWN;
    }
    
    EVP_CIPHER_CTX ctx;
    EVP_CIPHER_CTX_init(&ctx);
    
    result = EVP_DecryptInit_ex(&ctx, evp_cipher, 0, key, iv);
    if(!result) {
        fprintf(stderr, "cannot initialize cipher\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    if(cipher == SG_CIPHER_AES_CTR_NOPADDING) {
        result = EVP_CIPHER_CTX_set_padding(&ctx, 0);
        if(!result) {
            fprintf(stderr, "cannot set padding\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }
    
    out_buf = malloc(sizeof(uint8_t) * (ciphertext_len + EVP_CIPHER_block_size(evp_cipher)));
    if(!out_buf) {
        fprintf(stderr, "cannot allocate output buffer\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    int out_len = 0;
    result = EVP_DecryptUpdate(&ctx,
                               out_buf, &out_len, ciphertext, ciphertext_len);
    if(!result) {
        fprintf(stderr, "cannot decrypt ciphertext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    int final_len = 0;
    result = EVP_DecryptFinal_ex(&ctx, out_buf + out_len, &final_len);
    if(!result) {
        fprintf(stderr, "cannot finish decrypting ciphertext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }
    
    *output = signal_buffer_create(out_buf, out_len + final_len);
    
complete:
    EVP_CIPHER_CTX_cleanup(&ctx);
    if(out_buf) {
        free(out_buf);
    }
    return result;
}

void setup_test_crypto_provider(signal_context *context)
{
    signal_crypto_provider provider = {
        .random_func = test_random_generator,
        .hmac_sha256_init_func = test_hmac_sha256_init,
        .hmac_sha256_update_func = test_hmac_sha256_update,
        .hmac_sha256_final_func = test_hmac_sha256_final,
        .hmac_sha256_cleanup_func = test_hmac_sha256_cleanup,
        .sha512_digest_init_func = test_sha512_digest_init,
        .sha512_digest_update_func = test_sha512_digest_update,
        .sha512_digest_final_func = test_sha512_digest_final,
        .sha512_digest_cleanup_func = test_sha512_digest_cleanup,
        .encrypt_func = test_encrypt,
        .decrypt_func = test_decrypt,
        .user_data = 0
    };
    
    signal_context_set_crypto_provider(context, &provider);
}

/*------------------------------------------------------------------------*/

//typedef struct {
//    int64_t recipient_id;
//    int32_t device_id;
//} test_session_store_session_key;
//
//typedef struct {
//    test_session_store_session_key key;
//    signal_buffer *record;
//    UT_hash_handle hh;
//} test_session_store_session;
//
//typedef struct {
//    test_session_store_session *sessions;
//} test_session_store_data;

//int test_session_store_load_session(signal_buffer **record, const signal_protocol_address *address, void *user_data)
//{
//    test_session_store_data *data = user_data;
//    
//    test_session_store_session *s;
//    
//    test_session_store_session l;
//    memset(&l, 0, sizeof(test_session_store_session));
//    l.key.recipient_id = jenkins_hash(address->name, address->name_len);
//    l.key.device_id = address->device_id;
//    HASH_FIND(hh, data->sessions, &l.key, sizeof(test_session_store_session_key), s);
//    
//    if(!s) {
//        return 0;
//    }
//    signal_buffer *result = signal_buffer_copy(s->record);
//    if(!result) {
//        return SG_ERR_NOMEM;
//    }
//    *record = result;
//    return 1;
//}

int realm_session_store_load_session(signal_buffer **record, const signal_protocol_address *address, void *user_data)
{
    NSString *name = [NSString stringWithUTF8String:address->name];
    NSString *key = [SessionData calcIdWithName:name deviceId:address->device_id];
    SessionData *sd = [RealmDbHelper getSessionDataWithKey:key];
    if (sd == nil) {
        return 0;
    }
    *record = signal_buffer_create([sd.sessionRecord bytes], [sd.sessionRecord length]);
    return 1;
}

//int test_session_store_get_sub_device_sessions(signal_int_list **sessions, const char *name, size_t name_len, void *user_data)
//{
//    test_session_store_data *data = user_data;
//    
//    signal_int_list *result = signal_int_list_alloc();
//    if(!result) {
//        return SG_ERR_NOMEM;
//    }
//    
//    int64_t recipient_hash = jenkins_hash(name, name_len);
//    test_session_store_session *cur_node;
//    test_session_store_session *tmp_node;
//    HASH_ITER(hh, data->sessions, cur_node, tmp_node) {
//        if(cur_node->key.recipient_id == recipient_hash) {
//            signal_int_list_push_back(result, cur_node->key.device_id);
//        }
//    }
//    
//    *sessions = result;
//    return 0;
//}

int realm_session_store_get_sub_device_sessions(signal_int_list **sessions, const char *name, size_t name_len, void *user_data)
{
    NSString *nameStr = [NSString stringWithUTF8String:name];
    NSArray<SessionData *> *sessionsArr = [RealmDbHelper getSubDeviceSessionsWithName:nameStr];
    
    signal_int_list *result = signal_int_list_alloc();
    if(!result) {
        return SG_ERR_NOMEM;
    }
    
    for (SessionData *sd in sessionsArr) {
        signal_int_list_push_back(result, (int)sd.deviceId);
    }
    
    *sessions = result;
    return 0;
}


//int test_session_store_store_session(const signal_protocol_address *address, uint8_t *record, size_t record_len, void *user_data)
//{
//    test_session_store_data *data = user_data;
//    
//    test_session_store_session *s;
//    
//    test_session_store_session l;
//    memset(&l, 0, sizeof(test_session_store_session));
//    l.key.recipient_id = jenkins_hash(address->name, address->name_len);
//    l.key.device_id = address->device_id;
//    
//    signal_buffer *record_buf = signal_buffer_create(record, record_len);
//    if(!record_buf) {
//        return SG_ERR_NOMEM;
//    }
//    
//    HASH_FIND(hh, data->sessions, &l.key, sizeof(test_session_store_session_key), s);
//    
//    if(s) {
//        signal_buffer_free(s->record);
//        s->record = record_buf;
//    }
//    else {
//        s = malloc(sizeof(test_session_store_session));
//        if(!s) {
//            signal_buffer_free(record_buf);
//            return SG_ERR_NOMEM;
//        }
//        memset(s, 0, sizeof(test_session_store_session));
//        s->key.recipient_id = jenkins_hash(address->name, address->name_len);
//        s->key.device_id = address->device_id;
//        s->record = record_buf;
//        HASH_ADD(hh, data->sessions, key, sizeof(test_session_store_session_key), s);
//    }
//    
//    return 0;
//}

int realm_session_store_store_session(const signal_protocol_address *address, uint8_t *record, size_t record_len, void *user_data)
{
    NSData *recordData = [NSData dataWithBytes:record length:record_len];
    NSString *name = [NSString stringWithUTF8String:address->name];
    SessionData *sd = [[SessionData alloc] initWithSessionRecord:recordData name:name deviceId:address->device_id];
    [RealmDbHelper saveSessionData:sd];
    return 0;
}

//int test_session_store_contains_session(const signal_protocol_address *address, void *user_data)
//{
//    test_session_store_data *data = user_data;
//    test_session_store_session *s;
//    
//    test_session_store_session l;
//    memset(&l, 0, sizeof(test_session_store_session));
//    l.key.recipient_id = jenkins_hash(address->name, address->name_len);
//    l.key.device_id = address->device_id;
//    
//    HASH_FIND(hh, data->sessions, &l.key, sizeof(test_session_store_session_key), s);
//    
//    return (s == 0) ? 0 : 1;
//}

int realm_session_store_contains_session(const signal_protocol_address *address, void *user_data)
{
    NSString *name = [NSString stringWithUTF8String:address->name];
    NSString *key = [SessionData calcIdWithName:name deviceId:address->device_id];
    return [RealmDbHelper getSessionDataWithKey:key] == nil ? 0 : 1;
}

//int test_session_store_delete_session(const signal_protocol_address *address, void *user_data)
//{
//    int result = 0;
//    test_session_store_data *data = user_data;
//    test_session_store_session *s;
//    
//    test_session_store_session l;
//    memset(&l, 0, sizeof(test_session_store_session));
//    l.key.recipient_id = jenkins_hash(address->name, address->name_len);
//    l.key.device_id = address->device_id;
//    
//    HASH_FIND(hh, data->sessions, &l.key, sizeof(test_session_store_session_key), s);
//    
//    if(s) {
//        HASH_DEL(data->sessions, s);
//        signal_buffer_free(s->record);
//        free(s);
//        result = 1;
//    }
//    return result;
//}

int realm_session_store_delete_session(const signal_protocol_address *address, void *user_data)
{
    NSString *name = [NSString stringWithUTF8String:address->name];
    NSString *key = [SessionData calcIdWithName:name deviceId:address->device_id];
    return (int)[RealmDbHelper removeSessionDataWithKey:key];
}

//int test_session_store_delete_all_sessions(const char *name, size_t name_len, void *user_data)
//{
//    int result = 0;
//    test_session_store_data *data = user_data;
//    
//    int64_t recipient_hash = jenkins_hash(name, name_len);
//    test_session_store_session *cur_node;
//    test_session_store_session *tmp_node;
//    HASH_ITER(hh, data->sessions, cur_node, tmp_node) {
//        if(cur_node->key.recipient_id == recipient_hash) {
//            HASH_DEL(data->sessions, cur_node);
//            signal_buffer_free(cur_node->record);
//            free(cur_node);
//            result++;
//        }
//    }
//    
//    return result;
//}

int realm_session_store_delete_all_sessions(const char *name, size_t name_len, void *user_data)
{
    NSString *nameStr = [NSString stringWithUTF8String:name];
    return (int)[RealmDbHelper removeAllSessionDataWithName:nameStr];
}

//void test_session_store_destroy(void *user_data)
//{
//    test_session_store_data *data = user_data;
//    
//    test_session_store_session *cur_node;
//    test_session_store_session *tmp_node;
//    HASH_ITER(hh, data->sessions, cur_node, tmp_node) {
//        HASH_DEL(data->sessions, cur_node);
//        signal_buffer_free(cur_node->record);
//        free(cur_node);
//    }
//    
//    free(data);
//}

void realm_session_store_destroy(void *user_data)
{
    // empty
}

void setup_realm_session_store(signal_protocol_store_context *context)
{
//    test_session_store_data *data = malloc(sizeof(test_session_store_data));
//    memset(data, 0, sizeof(test_session_store_data));
    
    signal_protocol_session_store store = {
        .load_session_func = realm_session_store_load_session,
        .get_sub_device_sessions_func = realm_session_store_get_sub_device_sessions,
        .store_session_func = realm_session_store_store_session,
        .contains_session_func = realm_session_store_contains_session,
        .delete_session_func = realm_session_store_delete_session,
        .delete_all_sessions_func = realm_session_store_delete_all_sessions,
        .destroy_func = realm_session_store_destroy,
        .user_data = NULL
    };
    
    signal_protocol_store_context_set_session_store(context, &store);
}

/*------------------------------------------------------------------------*/

//typedef struct {
//    uint32_t key_id;
//    signal_buffer *key_record;
//    UT_hash_handle hh;
//} test_pre_key_store_key;
//
//typedef struct {
//    test_pre_key_store_key *keys;
//} test_pre_key_store_data;

//int test_pre_key_store_load_pre_key(signal_buffer **record, uint32_t pre_key_id, void *user_data)
//{
//    test_pre_key_store_data *data = user_data;
//    
//    test_pre_key_store_key *s;
//    
//    HASH_FIND(hh, data->keys, &pre_key_id, sizeof(uint32_t), s);
//    if(s) {
//        *record = signal_buffer_copy(s->key_record);
//        return SG_SUCCESS;
//    }
//    else {
//        return SG_ERR_INVALID_KEY_ID;
//    }
//}

int realm_pre_key_store_load_pre_key(signal_buffer **record, uint32_t pre_key_id, void *user_data)
{
    PreKeyData *pkd = [RealmDbHelper getPreKeyDataWithId:pre_key_id];
    if (pkd == nil) {
        return SG_ERR_INVALID_KEY_ID;
    }
    *record = signal_buffer_create([pkd.keyRecord bytes], [pkd.keyRecord length]);
    return SG_SUCCESS;
}

//int test_pre_key_store_store_pre_key(uint32_t pre_key_id, uint8_t *record, size_t record_len, void *user_data)
//{
//    test_pre_key_store_data *data = user_data;
//    
//    test_pre_key_store_key *s;
//    
//    signal_buffer *key_buf = signal_buffer_create(record, record_len);
//    if(!key_buf) {
//        return SG_ERR_NOMEM;
//    }
//    
//    HASH_FIND(hh, data->keys, &pre_key_id, sizeof(uint32_t), s);
//    if(s) {
//        signal_buffer_free(s->key_record);
//        s->key_record = key_buf;
//    }
//    else {
//        s = malloc(sizeof(test_pre_key_store_key));
//        if(!s) {
//            signal_buffer_free(key_buf);
//            return SG_ERR_NOMEM;
//        }
//        memset(s, 0, sizeof(test_pre_key_store_key));
//        s->key_id = pre_key_id;
//        s->key_record = key_buf;
//        HASH_ADD(hh, data->keys, key_id, sizeof(uint32_t), s);
//    }
//    
//    return 0;
//}

int realm_pre_key_store_store_pre_key(uint32_t pre_key_id, uint8_t *record, size_t record_len, void *user_data)
{
    NSData *recordData = [NSData dataWithBytes:record length:record_len];
    PreKeyData *pkd = [[PreKeyData alloc] initWithId:pre_key_id keyRecord:recordData];
    [RealmDbHelper savePreKeyData:pkd];
    return 0;
}

//int test_pre_key_store_contains_pre_key(uint32_t pre_key_id, void *user_data)
//{
//    test_pre_key_store_data *data = user_data;
//    
//    test_pre_key_store_key *s;
//    HASH_FIND(hh, data->keys, &pre_key_id, sizeof(uint32_t), s);
//    
//    return (s == 0) ? 0 : 1;
//}

int realm_pre_key_store_contains_pre_key(uint32_t pre_key_id, void *user_data)
{
    return [RealmDbHelper getPreKeyDataWithId:pre_key_id] == nil ? 0 : 1;
}

//int test_pre_key_store_remove_pre_key(uint32_t pre_key_id, void *user_data)
//{
//    test_pre_key_store_data *data = user_data;
//    
//    test_pre_key_store_key *s;
//    HASH_FIND(hh, data->keys, &pre_key_id, sizeof(uint32_t), s);
//    if(s) {
//        HASH_DEL(data->keys, s);
//        signal_buffer_free(s->key_record);
//        free(s);
//    }
//    
//    return 0;
//}

int realm_pre_key_store_remove_pre_key(uint32_t pre_key_id, void *user_data)
{
    [RealmDbHelper removePreKeyDataWithId:pre_key_id];
    return 0;
}

//void test_pre_key_store_destroy(void *user_data)
//{
//    test_pre_key_store_data *data = user_data;
//    
//    test_pre_key_store_key *cur_node;
//    test_pre_key_store_key *tmp_node;
//    HASH_ITER(hh, data->keys, cur_node, tmp_node) {
//        HASH_DEL(data->keys, cur_node);
//        signal_buffer_free(cur_node->key_record);
//        free(cur_node);
//    }
//    free(data);
//}

void realm_pre_key_store_destroy(void *user_data)
{
    // empty
}

void setup_realm_pre_key_store(signal_protocol_store_context *context)
{
//    test_pre_key_store_data *data = malloc(sizeof(test_pre_key_store_data));
//    memset(data, 0, sizeof(test_pre_key_store_data));
    
    signal_protocol_pre_key_store store = {
        .load_pre_key = realm_pre_key_store_load_pre_key,
        .store_pre_key = realm_pre_key_store_store_pre_key,
        .contains_pre_key = realm_pre_key_store_contains_pre_key,
        .remove_pre_key = realm_pre_key_store_remove_pre_key,
        .destroy_func = realm_pre_key_store_destroy,
        .user_data = NULL
    };
    
    signal_protocol_store_context_set_pre_key_store(context, &store);
}

/*------------------------------------------------------------------------*/

//typedef struct {
//    uint32_t key_id;
//    signal_buffer *key_record;
//    UT_hash_handle hh;
//} test_signed_pre_key_store_key;
//
//typedef struct {
//    test_signed_pre_key_store_key *keys;
//} test_signed_pre_key_store_data;


//int test_signed_pre_key_store_load_signed_pre_key(signal_buffer **record, uint32_t signed_pre_key_id, void *user_data)
//{
//    test_signed_pre_key_store_data *data = user_data;
//    test_signed_pre_key_store_key *s;
//    
//    HASH_FIND(hh, data->keys, &signed_pre_key_id, sizeof(uint32_t), s);
//    if(s) {
//        *record = signal_buffer_copy(s->key_record);
//        return SG_SUCCESS;
//    }
//    else {
//        return SG_ERR_INVALID_KEY_ID;
//    }
//}

int realm_signed_pre_key_store_load_signed_pre_key(signal_buffer **record, uint32_t signed_pre_key_id, void *user_data)
{
    LocalSignedPreKeyData *lspkd = [RealmDbHelper getLocalSignedPreKeyDataWithId:signed_pre_key_id];
    if (lspkd == nil) {
        return SG_ERR_INVALID_KEY_ID;
    }
    *record = signal_buffer_create([lspkd.keyRecord bytes], [lspkd.keyRecord length]);
    return SG_SUCCESS;
}

//int test_signed_pre_key_store_store_signed_pre_key(uint32_t signed_pre_key_id, uint8_t *record, size_t record_len, void *user_data)
//{
//    test_signed_pre_key_store_data *data = user_data;
//    test_signed_pre_key_store_key *s;
//    
//    signal_buffer *key_buf = signal_buffer_create(record, record_len);
//    if(!key_buf) {
//        return SG_ERR_NOMEM;
//    }
//    
//    HASH_FIND(hh, data->keys, &signed_pre_key_id, sizeof(uint32_t), s);
//    if(s) {
//        signal_buffer_free(s->key_record);
//        s->key_record = key_buf;
//    }
//    else {
//        s = malloc(sizeof(test_signed_pre_key_store_key));
//        if(!s) {
//            signal_buffer_free(key_buf);
//            return SG_ERR_NOMEM;
//        }
//        memset(s, 0, sizeof(test_signed_pre_key_store_key));
//        s->key_id = signed_pre_key_id;
//        s->key_record = key_buf;
//        HASH_ADD(hh, data->keys, key_id, sizeof(uint32_t), s);
//    }
//    
//    return 0;
//}

int realm_signed_pre_key_store_store_signed_pre_key(uint32_t signed_pre_key_id, uint8_t *record, size_t record_len, void *user_data)
{
    NSData *recordData = [NSData dataWithBytes:record length:record_len];
    LocalSignedPreKeyData *lspkd = [[LocalSignedPreKeyData alloc] initWithId:signed_pre_key_id keyRecord:recordData];
    [RealmDbHelper saveLocalSignedPreKeyData:lspkd];
    return 0;
}

//int test_signed_pre_key_store_contains_signed_pre_key(uint32_t signed_pre_key_id, void *user_data)
//{
//    test_signed_pre_key_store_data *data = user_data;
//    
//    test_signed_pre_key_store_key *s;
//    HASH_FIND(hh, data->keys, &signed_pre_key_id, sizeof(uint32_t), s);
//    
//    return (s == 0) ? 0 : 1;
//}

int realm_signed_pre_key_store_contains_signed_pre_key(uint32_t signed_pre_key_id, void *user_data)
{
    return [RealmDbHelper getLocalSignedPreKeyDataWithId:signed_pre_key_id] == nil ? 0 : 1;
}

//int test_signed_pre_key_store_remove_signed_pre_key(uint32_t signed_pre_key_id, void *user_data)
//{
//    test_signed_pre_key_store_data *data = user_data;
//    
//    test_signed_pre_key_store_key *s;
//    HASH_FIND(hh, data->keys, &signed_pre_key_id, sizeof(uint32_t), s);
//    if(s) {
//        HASH_DEL(data->keys, s);
//        signal_buffer_free(s->key_record);
//        free(s);
//    }
//    
//    return 0;
//}

int realm_signed_pre_key_store_remove_signed_pre_key(uint32_t signed_pre_key_id, void *user_data)
{
    [RealmDbHelper removeLocalSignedPreKeyDataWithId:signed_pre_key_id];
    return 0;
}


//void test_signed_pre_key_store_destroy(void *user_data)
//{
//    test_signed_pre_key_store_data *data = user_data;
//    
//    test_signed_pre_key_store_key *cur_node;
//    test_signed_pre_key_store_key *tmp_node;
//    HASH_ITER(hh, data->keys, cur_node, tmp_node) {
//        HASH_DEL(data->keys, cur_node);
//        signal_buffer_free(cur_node->key_record);
//        free(cur_node);
//    }
//    free(data);
//}

void realm_signed_pre_key_store_destroy(void *user_data)
{
}

void setup_realm_signed_pre_key_store(signal_protocol_store_context *context)
{
//    test_signed_pre_key_store_data *data = malloc(sizeof(test_signed_pre_key_store_data));
//    memset(data, 0, sizeof(test_signed_pre_key_store_data));
    
    signal_protocol_signed_pre_key_store store = {
        .load_signed_pre_key = realm_signed_pre_key_store_load_signed_pre_key,
        .store_signed_pre_key = realm_signed_pre_key_store_store_signed_pre_key,
        .contains_signed_pre_key = realm_signed_pre_key_store_contains_signed_pre_key,
        .remove_signed_pre_key = realm_signed_pre_key_store_remove_signed_pre_key,
        .destroy_func = realm_signed_pre_key_store_destroy,
        .user_data = NULL
    };
    
    signal_protocol_store_context_set_signed_pre_key_store(context, &store);
}

/*------------------------------------------------------------------------*/

typedef struct {
    int64_t recipient_id;
    signal_buffer *identity_key;
    UT_hash_handle hh;
} test_identity_store_key;

typedef struct {
    test_identity_store_key *keys;
    signal_buffer *identity_key_public;
    signal_buffer *identity_key_private;
    uint32_t local_registration_id;
} test_identity_store_data;

//int test_identity_key_store_get_identity_key_pair(signal_buffer **public_data, signal_buffer **private_data, void *user_data)
//{
//    test_identity_store_data *data = user_data;
//    *public_data = signal_buffer_copy(data->identity_key_public);
//    *private_data = signal_buffer_copy(data->identity_key_private);
//    return 0;
//}

int realm_identity_key_store_get_identity_key_pair(signal_buffer **public_data, signal_buffer **private_data, void *user_data)
{
    LocalIdentityData *identityData = [RealmDbHelper getLocalIdentityData];
    if (identityData == nil || identityData.publicKey == nil || identityData.privateKey == nil) {
        return -1;
    }
    *public_data = signal_buffer_create([identityData.publicKey bytes], [identityData.publicKey length]);
    *private_data = signal_buffer_create([identityData.privateKey bytes], [identityData.privateKey length]);
    return 0;
}


//int test_identity_key_store_get_local_registration_id(void *user_data, uint32_t *registration_id)
//{
//    test_identity_store_data *data = user_data;
//    *registration_id = data->local_registration_id;
//    return 0;
//}

int realm_identity_key_store_get_local_registration_id(void *user_data, uint32_t *registration_id)
{
    RegistrationIdData *regIdData = [RealmDbHelper getRegistrationIdData];
    if (regIdData == nil) {
        return -1;
    }
    *registration_id = (uint32_t)regIdData.registrationId;
    return 0;
}

//int test_identity_key_store_save_identity(const signal_protocol_address *address, uint8_t *key_data, size_t key_len, void *user_data)
//{
//    test_identity_store_data *data = user_data;
//    
//    test_identity_store_key *s;
//    
//    signal_buffer *key_buf = signal_buffer_create(key_data, key_len);
//    if(!key_buf) {
//        return SG_ERR_NOMEM;
//    }
//    
//    int64_t recipient_hash = jenkins_hash(address->name, address->name_len);
//    
//    HASH_FIND(hh, data->keys, &recipient_hash, sizeof(int64_t), s);
//    if(s) {
//        signal_buffer_free(s->identity_key);
//        s->identity_key = key_buf;
//    }
//    else {
//        s = malloc(sizeof(test_identity_store_key));
//        if(!s) {
//            signal_buffer_free(key_buf);
//            return SG_ERR_NOMEM;
//        }
//        memset(s, 0, sizeof(test_identity_store_key));
//        s->recipient_id = recipient_hash;
//        s->identity_key = key_buf;
//        HASH_ADD(hh, data->keys, recipient_id, sizeof(int64_t), s);
//    }
//    
//    return 0;
//}

int realm_identity_key_store_save_identity(const signal_protocol_address *address, uint8_t *key_data, size_t key_len, void *user_data)
{
    NSData *keyData = [NSData dataWithBytes:key_data length:key_len];
    NSString *name = [NSString stringWithUTF8String:address->name];
    RemoteIdentityData *rid = [[RemoteIdentityData alloc] initWithKey:keyData name:name deviceId:address->device_id];
    [RealmDbHelper saveRemoteIdentityData:rid];
    return 0;
}

//int test_identity_key_store_is_trusted_identity(const signal_protocol_address *address, uint8_t *key_data, size_t key_len, void *user_data)
//{
//    test_identity_store_data *data = user_data;
//    
//    int64_t recipient_hash = jenkins_hash(address->name, address->name_len);
//    
//    test_identity_store_key *s;
//    HASH_FIND(hh, data->keys, &recipient_hash, sizeof(int64_t), s);
//    
//    if(s) {
//        uint8_t *store_data = signal_buffer_data(s->identity_key);
//        size_t store_len = signal_buffer_len(s->identity_key);
//        if(store_len != key_len) {
//            return 0;
//        }
//        if(memcmp(key_data, store_data, key_len) == 0) {
//            return 1;
//        }
//        else {
//            return 0;
//        }
//    }
//    else {
//        return 1;
//    }
//}

int realm_identity_key_store_is_trusted_identity(const signal_protocol_address *address, uint8_t *key_data, size_t key_len, void *user_data)
{
    NSString *name = [NSString stringWithUTF8String:address->name];
    NSString *key = [RemoteIdentityData calcIdWithName:name deviceId:address->device_id];
    RemoteIdentityData *rid = [RealmDbHelper getRemoteIdentityDataWithKey:key];
    if (rid == nil) {
        return 1;
    }
    if ([rid.key length] != key_len) {
        return 0;
    }
    if (memcmp([rid.key bytes], key_data, key_len) == 0) {
        return 1;
    } else {
        return 0;
    }
}

//void test_identity_key_store_destroy(void *user_data)
//{
//    test_identity_store_data *data = user_data;
//    
//    test_identity_store_key *cur_node;
//    test_identity_store_key *tmp_node;
//    HASH_ITER(hh, data->keys, cur_node, tmp_node) {
//        HASH_DEL(data->keys, cur_node);
//        signal_buffer_free(cur_node->identity_key);
//        free(cur_node);
//    }
//    signal_buffer_free(data->identity_key_public);
//    signal_buffer_free(data->identity_key_private);
//    free(data);
//}

void realm_identity_key_store_destroy(void *user_data)
{
    //empty
}


void setup_realm_identity_key_store(signal_protocol_store_context *context, signal_context *global_context)
{
//    test_identity_store_data *data = malloc(sizeof(test_identity_store_data));
//    memset(data, 0, sizeof(test_identity_store_data));
//    
//    //    ec_key_pair *identity_key_pair_keys = 0;
//    //    curve_generate_key_pair(global_context, &identity_key_pair_keys);
//    
//    //    ec_public_key *identity_key_public = ec_key_pair_get_public(identity_key_pair_keys);
//    //    ec_private_key *identity_key_private = ec_key_pair_get_private(identity_key_pair_keys);
//    
//    ec_public_key_serialize(&data->identity_key_public, identity_key_public);
//    ec_private_key_serialize(&data->identity_key_private, identity_key_private);
//    //    SIGNAL_UNREF(identity_key_pair_keys);
//    
//    //    data->local_registration_id = (rand() % 16380) + 1;
//    data->local_registration_id = local_registration_id;
    
    signal_protocol_identity_key_store store = {
        .get_identity_key_pair = realm_identity_key_store_get_identity_key_pair,
        .get_local_registration_id = realm_identity_key_store_get_local_registration_id,
        .save_identity = realm_identity_key_store_save_identity,
        .is_trusted_identity = realm_identity_key_store_is_trusted_identity,
        .destroy_func = realm_identity_key_store_destroy,
        .user_data = NULL
    };
    
    signal_protocol_store_context_set_identity_key_store(context, &store);
}

/*------------------------------------------------------------------------*/

//void setup_test_store_context(signal_protocol_store_context **context, signal_context *global_context,
//                              ratchet_identity_key_pair *identity_key_pair, uint32_t local_registration_id)
void setup_realm_store_context(signal_protocol_store_context **context, signal_context *global_context)
{
    int result = 0;
    
    signal_protocol_store_context *store_context = 0;
    result = signal_protocol_store_context_create(&store_context, global_context);
    //    ck_assert_int_eq(result, 0);
    
    setup_realm_session_store(store_context);
    setup_realm_pre_key_store(store_context);
    setup_realm_signed_pre_key_store(store_context);
    setup_realm_identity_key_store(store_context, global_context);
    //    setup_test_sender_key_store(store_context, global_context);
    
    *context = store_context;
}

void test_log(int level, const char *message, size_t len, void *user_data)
{
    switch(level) {
        case SG_LOG_ERROR:
            fprintf(stderr, "[ERROR] %s\n", message);
            break;
        case SG_LOG_WARNING:
            fprintf(stderr, "[WARNING] %s\n", message);
            break;
        case SG_LOG_NOTICE:
            fprintf(stderr, "[NOTICE] %s\n", message);
            break;
        case SG_LOG_INFO:
            fprintf(stderr, "[INFO] %s\n", message);
            break;
        case SG_LOG_DEBUG:
            fprintf(stderr, "[DEBUG] %s\n", message);
            break;
        default:
            fprintf(stderr, "[%d] %s\n", level, message);
            break;
    }
}
