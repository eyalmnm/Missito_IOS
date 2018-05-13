//
//  OTPKeysData.swift
//  Missito
//
//  Created by Alex Gridnev on 3/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

struct OTPKeysData: Gloss.Decodable {
    
    let startId: UInt32
    let keys: [String]
    
    init(startId: UInt32, keys: [String]) {
        self.startId = startId
        self.keys = keys
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let startId: UInt32 = "startId" <~~ json,
            let keys: [String] = "keys" <~~ json
            else {
                return nil
        }
        self.startId = startId
        self.keys = keys
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "startId" ~~> self.startId,
            "keys" ~~> self.keys
            ])
    }
    
}

// -d "{\"start_id\":0, \"otp_keys\":[\"key0\",\"key1\",\"key2\",\"key3\"]}"
