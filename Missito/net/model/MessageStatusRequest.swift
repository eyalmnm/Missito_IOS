//
//  MessageStatusRequest.swift
//  Missito
//
//  Created by Alex Gridnev on 6/1/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

struct MessageStatusRequest: Gloss.Encodable {
    
    let received: [String]
    let seen: [String]
    
    init(received: [String], seen: [String]) {
        self.received = received
        self.seen = seen
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "received" ~~> self.received,
            "seen" ~~> self.seen
            ])
    }
}
