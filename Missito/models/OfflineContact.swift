//
//  OfflineContact.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/20/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Gloss

@objc final class OfflineContact: NSObject, Gloss.Decodable {
    
    let userId: String
    let lastSeen: UInt64
    let deviceId: Int
    
    init?(json: JSON) {
        guard let userId: String = "userId" <~~ json,
            let lastSeen: UInt64 = "lastSeen" <~~ json,
            let deviceId: Int = "deviceId" <~~ json
            else {
                return nil
        }
        
        self.userId = Utils.fixPhoneFormat(userId)
        self.lastSeen = lastSeen
        self.deviceId = deviceId
    }
    
    init(_ userId: String, _ lastSeen: UInt64, _ deviceId: Int) {
        self.userId = userId
        self.lastSeen = lastSeen
        self.deviceId = deviceId
    }
}
