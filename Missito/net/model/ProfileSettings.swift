//
//  ProfileSettings.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Gloss

struct ProfileSettings: Gloss.Decodable, Gloss.Encodable {

    var messageStatus: Bool?
    var presenceStatus: Bool?
    
    init() {}
    
    // MARK: - Deserialization
    
    init(json: JSON) {
        self.messageStatus = "messageStatus" <~~ json ?? true
        self.presenceStatus = "presenceStatus" <~~ json ?? true
    }
    
    init(messageStatus: Bool?, presenceStatus: Bool?) {
        self.messageStatus = messageStatus
        self.presenceStatus = presenceStatus
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "messageStatus" ~~> self.messageStatus,
            "presenceStatus" ~~> self.presenceStatus
            ])
    }

}
