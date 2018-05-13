//
//  SignalBridge.h
//  Missito
//
//  Created by Alex Gridnev on 3/2/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

#ifndef SignalBridge_h
#define SignalBridge_h

#include "signal_protocol.h"

const int SB_SG_SUCCESS = SG_SUCCESS;

const int SB_SG_ERR_UNKNOWN = SG_ERR_UNKNOWN;
const int SB_SG_ERR_DUPLICATE_MESSAGE = SG_ERR_DUPLICATE_MESSAGE;
const int SB_SG_ERR_INVALID_KEY = SG_ERR_INVALID_KEY;
const int SB_SG_ERR_INVALID_KEY_ID = SG_ERR_INVALID_KEY_ID;
const int SB_SG_ERR_INVALID_MAC = SG_ERR_INVALID_MAC;
const int SB_SG_ERR_INVALID_MESSAGE = SG_ERR_INVALID_MESSAGE;
const int SB_SG_ERR_INVALID_VERSION = SG_ERR_INVALID_VERSION;
const int SB_SG_ERR_LEGACY_MESSAGE = SG_ERR_LEGACY_MESSAGE;
const int SB_SG_ERR_NO_SESSION = SG_ERR_NO_SESSION;
const int SB_SG_ERR_STALE_KEY_EXCHANGE = SG_ERR_STALE_KEY_EXCHANGE;
const int SB_SG_ERR_UNTRUSTED_IDENTITY = SG_ERR_UNTRUSTED_IDENTITY;
const int SB_SG_ERR_VRF_SIG_VERIF_FAILED = SG_ERR_VRF_SIG_VERIF_FAILED;
const int SB_SG_ERR_INVALID_PROTO_BUF = SG_ERR_INVALID_PROTO_BUF;
const int SB_SG_ERR_FP_VERSION_MISMATCH = SG_ERR_FP_VERSION_MISMATCH;
const int SB_SG_ERR_FP_IDENT_MISMATCH = SG_ERR_FP_IDENT_MISMATCH;

#endif /* SignalBridge_h */