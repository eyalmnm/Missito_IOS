//
//  ChatMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class ChatMessage: BaseChatMessage {
    let text: String?
    var serverId: String?
    let id: String?
    let attachment: RealmAttachment?
    var progress: Float?
    
    init(text: String?, direction: Direction, timeSent: Date, id: String?, type: MessageType, serverId: String? = nil, attachment: RealmAttachment? = nil) {
        self.text = text
        self.serverId = serverId
        self.id = id
        self.attachment = attachment
        super.init(direction: direction, date: timeSent, type: type)
    }
    
    init(realmMessage: RealmMessage, direction: Direction) {
        text = realmMessage.msg
        serverId = realmMessage.serverMsgId
        attachment = realmMessage.attachment
        id = realmMessage.id
        super.init(direction: direction, date: realmMessage.timeSent, type: realmMessage.getType())
    }
    
    static func make(from realmMessage: RealmMessage, companion: Contact?) -> ChatMessage {
        if realmMessage.destUid == companion?.phone {
            return OutgoingChatMessage(realmMessage: realmMessage, destContact: companion)
        } else {
            return IncomingChatMessage(realmMessage: realmMessage, senderContact: companion!)
        }
    }
}
