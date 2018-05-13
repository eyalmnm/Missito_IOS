//
//  MessageStatus.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/31/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

@objc final class MessageStatus: NSObject, Gloss.Decodable {
    
    let serverMsgId: String
    let status: String
    
    init?(json: JSON) {
        guard let serverMsgId: String = "msgId" <~~ json,
            let status: String = "status" <~~ json
            else {
                return nil
        }
        
        self.serverMsgId = serverMsgId
        self.status = status
    }
}
