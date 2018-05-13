//
//  OutgoingMessage.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/15/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

struct OutgoingMessage: Gloss.Encodable {

    let destUid: String
    let destDeviceId: Int
    let data: String
    let type: String
    let qos: QoS
    
    init(destUid: String, destDeviceId: Int, data: String, type: String, qos: QoS) {
        self.destUid = destUid
        self.destDeviceId = destDeviceId
        self.data = data
        self.type = type
        self.qos = qos
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "destUid" ~~> Utils.removePlusFrom(phone: destUid),
            "destDeviceId" ~~> destDeviceId,
            "data" ~~> self.data,
            "type" ~~> self.type,
            "qos" ~~> self.qos.rawValue
            ])
    }
    
    enum QoS : String {
        /*
         transient - If destination user is online message will be send, otherwise it will be discarded (no offline messages, no push notifications)
         */
        case transient = "transient"
        /*
         regular - If destination user is online message will be send, otherwise it will be delivered once he is online (no push notifications)
         */
        case regular = "regular"
        /*
         mandatory - Same as regular, but with push notifications.
         */
        case mandatory = "mandatory"
    }
}
