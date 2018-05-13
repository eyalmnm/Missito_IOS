//
//  ContactsBlockStatusUpdateMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 5/30/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

struct ContactsBlockStatusUpdateMessage: Gloss.Encodable {
    
    let block: [String]
    let normal: [String]
    let muted: [String]
    
    init(normal: [String], block: [String], muted: [String]) {
        self.normal = normal
        self.block = block
        self.muted = muted
    }
        
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "block" ~~> self.block,
            "normal" ~~> self.normal,
            "muted" ~~> self.muted
            ])
    }
}
