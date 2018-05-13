//
//  MissitoMessage.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/1/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class MissitoMessage {
    
    let body: MessageBody
    let incomingMessage: IncomingMessage
    let id: String
    
    init(id: String, body: MessageBody, incomingMessage: IncomingMessage) {
        self.body = body
        self.incomingMessage = incomingMessage
        self.id = id
    }
    
    func getType() -> MessageType {
        if body.isTyping() {
            return .typing
        }
        var type = MessageType.text
        if let attach = body.attach {
            if attach.images?.count ?? 0 > 0 {
                type = .image
            }
            if attach.contacts?.count ?? 0 > 0 {
                type = .contact
            }
            if attach.locations?.count ?? 0 > 0 {
                type = .geo
            }
            if attach.audio?.count ?? 0 > 0 {
                type = .audio
            }
            if attach.video?.count ?? 0 > 0 {
                type = .video
            }
        }
        return type
    }
    
}
