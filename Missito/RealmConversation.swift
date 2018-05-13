//
//  RealmConversation.swift
//  Missito
//
//  Created by Alex Gridnev on 8/15/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RealmConversation: Object {
    
    dynamic var id: String = ""
    dynamic var lastMessage: RealmMessage? = nil
    dynamic var unreadCount = 0
    var counterparts = List<RealmMissitoContact>()

    convenience init(counterparts: [RealmMissitoContact], lastMessage: RealmMessage? = nil) {
        self.init()
        self.counterparts = List<RealmMissitoContact>(counterparts)
        self.lastMessage = lastMessage
        self.id = UUID().uuidString
    }
    
    override static func primaryKey() -> String {
        return "id"
    }
    
}
