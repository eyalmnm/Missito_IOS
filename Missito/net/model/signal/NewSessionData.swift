//
//  NewSessionData.swift
//  Missito
//
//  Created by Alex Gridnev on 3/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class NewSessionData: NSObject, Gloss.Decodable {
    
    let identity: IdentityData
    let signedPreKey: SignedPreKeyData
    let otpk: OTPKeyData
    
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let identity: IdentityData = "identity" <~~ json,
            let signedPreKey: SignedPreKeyData = "signed_pre_key_public" <~~ json,
            let otpk: OTPKeyData = "otpk" <~~ json
            else {
                return nil
        }
        self.identity = identity
        self.signedPreKey = signedPreKey
        self.otpk = otpk
    }
    
    
}
//    # reply: {"identity":{"identity_public_key":"identity-key-data","reg_id":123},"signed_pre_key_public":{"id":223,"data":"some-data","signature":"signofit"},"otp":{"id":0,"data":"key0"}}
