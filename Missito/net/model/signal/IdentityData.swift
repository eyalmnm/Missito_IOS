//
//  IdentityData.swift
//  Missito
//
//  Created by Alex Gridnev on 3/9/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class IdentityData: NSObject, Gloss.Decodable {
    
    let registrationId: UInt32
    let identityPublicKey: String
    
    init(registrationId: UInt32, identityPublicKey: String) {
        self.registrationId = registrationId
        self.identityPublicKey = identityPublicKey
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let registrationId: UInt32 = "regId" <~~ json,
            let identityPublicKey: String = "identityPK" <~~ json
            else {
                return nil
        }
        
        self.registrationId = registrationId
        self.identityPublicKey = identityPublicKey
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "regId" ~~> self.registrationId,
            "identityPK" ~~> self.identityPublicKey
            ])
    }
    
}

//curl "http://missito:8080/identity/store?uid=55" -d "{\"reg_id\":123, \"identity_public_key\":\"identity-key-data\"}"
