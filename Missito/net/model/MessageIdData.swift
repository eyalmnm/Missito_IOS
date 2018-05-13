//
//  MessageIdData.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/18/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

struct MessageIdData: Gloss.Decodable {
    
    let serverMsgId: String
    
    init(serverMsgId: String) {
        self.serverMsgId = serverMsgId
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let serverMsgId: String = "messageId" <~~ json
            else {
                return nil
        }
        
        self.serverMsgId = serverMsgId
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "messageId" ~~> self.serverMsgId
            ])
    }
}
