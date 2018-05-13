//
//  OTPKeyData.swift
//  Missito
//
//  Created by Alex Gridnev on 3/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class OTPKeyData: NSObject, Gloss.Decodable {
    
    let keyId: UInt32
    let key: String
    
    init(keyId: UInt32, key: String) {
        self.keyId = keyId
        self.key = key
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let keyId: UInt32 = "id" <~~ json,
            let key: String = "data" <~~ json
            else {
                return nil
        }
        
        self.keyId = keyId
        self.key = key
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "id" ~~> self.keyId,
            "data" ~~> self.key
            ])
    }
    
}

// {"id":0,"data":"key0"}
