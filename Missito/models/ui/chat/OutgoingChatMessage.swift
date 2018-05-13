//
//  OutgoingChatMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class OutgoingChatMessage: ChatMessage {
    var status: RealmMessage.OutgoingMessageStatus
    var destContact: Contact? // Destination user contact
    
//    init(text: String?, timeSent: Date, id: String, serverId: String?, type: MessageType, attachment: RealmAttachment?, status: RealmMessage.OutgoingMessageStatus) {
//        self.status = status
//        super.init(text: text, direction: .outgoing, timeSent: timeSent, id: id, type: type, serverId: serverId, attachment: attachment)
//    }
    
    init(realmMessage: RealmMessage, destContact: Contact?) {
        status = realmMessage.outgoingStatus ?? .outgoing
        self.destContact = destContact
        super.init(realmMessage: realmMessage, direction: .outgoing)
    }
}
