//
//  SignedPreKeyData.swift
//  Missito
//
//  Created by Alex Gridnev on 3/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class SignedPreKeyData: NSObject, Gloss.Decodable {
    
    let keyId: UInt32
    let key: String
    let keySignature: String
    
    init(keyId: UInt32, key: String, keySignature: String) {
        self.keyId = keyId
        self.key = key
        self.keySignature = keySignature
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let keyId: UInt32 = "id" <~~ json,
            let key: String = "data" <~~ json,
            let keySignature: String = "signature" <~~ json
            else {
                return nil
        }
        self.keyId = keyId
        self.key = key
        self.keySignature = keySignature
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "id" ~~> self.keyId,
            "data" ~~> self.key,
            "signature" ~~> self.keySignature
            ])
    }
    
}

// -d "{\"id\":223, \"data\":\"some-data\", \"signature\":\"signofit\"}"
