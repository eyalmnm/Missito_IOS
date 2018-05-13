
//
//  BaseChatMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class BaseChatMessage {
    
    let direction: Direction
    var date: Date
    let type: MessageType
    var inGroupType = MessageInGroupType.single
    
    convenience init(){
        self.init(direction: Direction.outgoing, date: Date(), type: MessageType.text)
    }
    
    init(direction: Direction, date: Date, type: MessageType) {
        self.direction = direction
        self.date = date
        self.type = type
    }
    
    enum Direction {
        case incoming, outgoing
    }
    
    enum MessageInGroupType {
        case single, first, last, middle
    }
    
}
