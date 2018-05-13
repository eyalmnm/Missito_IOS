//
//  IncomingChatMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class IncomingChatMessage: ChatMessage {
    
    let senderContact: Contact
    let senderDeviceId: Int
    
    init(text: String?, timeSent: Date, id: String?, type: MessageType, serverId: String?, attachment: RealmAttachment?, senderContact: Contact, senderDeviceId: Int) {
        self.senderContact = senderContact
        self.senderDeviceId = senderDeviceId
        super.init(text: text, direction: .incoming, timeSent: timeSent, id: id, type: type, serverId: serverId, attachment: attachment)
    }
    
    convenience init(missitoMessage: MissitoMessage, senderContact: Contact) {
        self.init(text: missitoMessage.body.text ?? "",
                  timeSent: Date(timeIntervalSince1970: TimeInterval(missitoMessage.incomingMessage.timeSent)),
                  id: missitoMessage.id,
                  type: missitoMessage.getType(),
                  serverId: missitoMessage.id,
                  attachment: RealmAttachment.make(from: missitoMessage.body.attach),
                  senderContact: senderContact,
                  senderDeviceId: missitoMessage.incomingMessage.senderDeviceId)
    }
    
    init(realmMessage: RealmMessage, senderContact: Contact) {
        self.senderContact = senderContact
        self.senderDeviceId = realmMessage.senderDeviceId
        super.init(realmMessage: realmMessage, direction: .incoming)
    }
}
