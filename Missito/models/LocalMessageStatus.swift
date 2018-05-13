//
//  LocalMessagesStatus.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/6/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class LocalMessageStatus {
    
    let id: String
    let serverId: String
    let status: RealmMessage.OutgoingMessageStatus
    let timeSent: Date
    
    init(_ id: String, _ serverId: String, _ status: RealmMessage.OutgoingMessageStatus, _ timeSent: Date) {
        self.id = id
        self.serverId = serverId
        self.status = status
        self.timeSent = timeSent
    }
    
}
