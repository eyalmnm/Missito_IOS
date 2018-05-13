//
//  CloudTokenUpdate.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/15/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Gloss

struct CloudTokenUpdate: Gloss.Encodable  {

    let token: String
    let tokenType: String = "apple"
    let deviceId: String
    
    init(token: String) {
        self.token = token
        self.deviceId = UIDevice.current.identifierForVendor!.uuidString
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "token" ~~> self.token,
            "token_type" ~~> "apple",
            "device" ~~> self.deviceId
            ])
    }
}
