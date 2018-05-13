//
//  BrokerMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 3/15/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class BrokerMessage: NSObject, Gloss.Decodable {
    
    let messageType: String
    let body: String
    let senderUid: String
    
    init(messageType: String, body: String, senderUid: String) {
        self.messageType = messageType
        self.body = body
        self.senderUid = senderUid
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let messageType: String = "messageType" <~~ json,
            let body: String = "body" <~~ json,
            let senderUid: String = "sender_uid" <~~ json
            else {
                return nil
        }
        
        self.messageType = messageType
        self.body = body
        self.senderUid = senderUid
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "messageType" ~~> self.messageType,
            "body" ~~> self.body,
            "sender_uid" ~~> self.senderUid
            ])
    }
    
}
