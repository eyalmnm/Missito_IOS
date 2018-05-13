//
//  IncomingMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 5/19/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

@objc final class IncomingMessage: NSObject, Gloss.Decodable {
    
    let serverMsgId: String
    let senderUid: String
    let senderDeviceId: Int
    let msg: String
    let msgType: String
    let timeSent: UInt64
    
    init(id: String) {
        self.serverMsgId = id
        senderUid = ""
        senderDeviceId = 0
        msg = ""
        msgType = ""
        timeSent = 0
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let serverMsgId: String = "id" <~~ json,
            let senderUid: String = "senderUid" <~~ json,
            let senderDeviceId: Int = "senderDeviceId" <~~ json,
            let msg: String = "msg" <~~ json,
            let msgType: String = "msgType" <~~ json,
            let timeSent: UInt64 = "timeSent" <~~ json
            else {
                return nil
        }
        
        self.serverMsgId = serverMsgId
        self.senderUid = Utils.fixPhoneFormat(senderUid)
        self.senderDeviceId = senderDeviceId
        self.msg = msg
        self.msgType = msgType
        self.timeSent = timeSent
    }
    
}
