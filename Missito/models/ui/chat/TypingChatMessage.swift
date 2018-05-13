//
//  TypingChatMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class TypingChatMessage: BaseChatMessage {
    init(date: Date) {
        super.init(direction: .incoming, date: date, type: .typing)
    }
}
