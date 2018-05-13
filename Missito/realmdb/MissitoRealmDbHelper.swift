//
//  MissitorealmDbHelper.swift
//  Missito
//
//  Created by Alex Gridnev on 6/2/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import RealmSwift

class MissitoRealmDbHelper {
    
    static let UNREAD_COUNTER_UPDATE = NSNotification.Name(rawValue: "unread_counter_update")
    static let MISSITO_CONVERSATION_KEY = "missito_conversation_key"
    static let CONVERSATIONS_UPDATE = NSNotification.Name(rawValue: "conversations_update")
    
    static func updateMessagesIncomingStatus(withServerIds: [String], status: RealmMessage.IncomingMessageStatus) {
        guard !withServerIds.isEmpty else {
            return
        }
        
        let db = MissitoRealmDB.shared.database()
        
        let textMessages = db?.objects(RealmMessage.self).filter(NSPredicate.init(format: "serverMsgId IN %@", withServerIds))
        try! db?.write {
            if let textMessages = textMessages {
                for textMessage in textMessages {
                    textMessage.incomingStatus = status
                }
            }
        }
    }
    
    static func updateServerMsgId(uniqueId: String, serverMsgId: String) {
        let db = MissitoRealmDB.shared.database()
        if let message = db?.objects(RealmMessage.self).filter({$0.uniqueId == uniqueId}).first {
            try! db?.write {
                message.serverMsgId = serverMsgId
            }
        }
    }
    
    static func updateMessageOutgoingStatus(withServerId: String, status: RealmMessage.OutgoingMessageStatus) {
        guard !withServerId.isEmpty else {
            return
        }
        
        let db = MissitoRealmDB.shared.database()
        
        let textMessages = db?.objects(RealmMessage.self).filter(String.init(format: "serverMsgId = '%@'", withServerId))
        try! db?.write {
            if let textMessages = textMessages {
                for textMessage in textMessages {
                    if textMessage.outgoingStatus == RealmMessage.OutgoingMessageStatus.seen {
                        continue
                    }
                    textMessage.outgoingStatus = status
                    NSLog("MSG id=%@ serverId=%@ set to %@", textMessage.id, textMessage.serverMsgId ?? "no-srv-id", textMessage.outgoingStatusStr!)
                }
            }
        }
    }
    
    static func containsMessage(uniqueId: String) -> Bool {
        return MissitoRealmDbHelper.get(RealmMessage.self, String(format: "uniqueId = '%@'", uniqueId)) != nil
    }
    
    static func fetch<T: Object>(type: T.Type, condition: String? = nil) -> Results<T>? {
        if let db = MissitoRealmDB.shared.database() {
            if let condition = condition {
                return db.objects(type).filter(NSPredicate(format:condition))
            } else {
                return db.objects(type)
            }
        }
        
        return nil
    }
    
    static func fetch<T: Object>(type: T.Type, predicate: NSPredicate?) -> Results<T>? {
        if let db = MissitoRealmDB.shared.database() {
            if let predicate = predicate {
                return db.objects(type).filter(predicate)
            } else {
                return db.objects(type)
            }
        }
        
        return nil
    }

    
    static func get<T: Object>(_ type: T.Type, _ condition: String) -> T? {
        if let db = MissitoRealmDB.shared.database(), let obj = db.objects(type).filter(condition).first {
            return obj
        }
        return nil
    }
    
    static func write(_ type: Object.Type, _ value: Any, update: Bool = false) {
        if let db = MissitoRealmDB.shared.database() {
            do {
                try db.write {
                    db.create(type, value: value, update: update)
                }
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }
    }
    
    static func write(_ write: @escaping (_ db: Realm?, _ error: Error?) -> Void) {
        if let db = MissitoRealmDB.shared.database() {
            do {
                try db.write {
                    write(db, nil)
                }
            } catch let error {
                write(nil, error)
                NSLog(error.localizedDescription)
            }
        } else {
            write(nil, nil)
        }
    }
    
    static func writePhones(_ phones: [String]) {
        DispatchQueue.global().async {
            write { db, error in
                if let db = db {
                    for phone in phones {
                        db.create(PhoneBookNumber.self, value: PhoneBookNumber(phone: phone), update: false)
                    }
                }
            }
        }
    }
    
    static func updateAudioMessage(messageId: String, audio: RealmAudio) {
        MissitoRealmDbHelper.write {
            realm, error in
            if let message = MissitoRealmDbHelper.getMessage(with: messageId) {
                message.attachment?.audio[0] = audio
                realm?.create(RealmMessage.self, value: message, update: true)
            }
        }
    }
    
    static func markOutgoingMessageAsSent(_ msg: RealmMessage, serverId: String, timeSent: Date) {
        NSLog("markOutgoingMessageAsSent id=%@, serverId=%@", msg.id, serverId)
        write { db, error in
            if let _ = db {
                msg.serverMsgId = serverId
                msg.outgoingStatus = RealmMessage.OutgoingMessageStatus.sent
                msg.timeSent = timeSent
            }
        }
    }
    
    static func updateUnreadMessagesCounter(for phone: String, increment: Bool = true) {
        if let db = MissitoRealmDB.shared.database() {
            
            if let defaultConversation = getDefaultConversation(phone: phone) {
                try! db.write {
                    defaultConversation.unreadCount = (increment ? defaultConversation.unreadCount + 1 : 0)
                }
                NotificationCenter.default.post(name: MissitoRealmDbHelper.UNREAD_COUNTER_UPDATE, object: nil,
                                                userInfo: [MissitoRealmDbHelper.MISSITO_CONVERSATION_KEY : defaultConversation])
            }
        }
    }
    
    static func getMissitoContacts() -> [RealmMissitoContact]? {
        if let fetched = MissitoRealmDbHelper.fetch(type: RealmMissitoContact.self) {
            var contacts: [RealmMissitoContact] = []
            for x in fetched {
                contacts.append(x)
            }
            return contacts
        }
        return nil
    }
    
    static func saveMissitoContacts(_ contacts: [RealmMissitoContact]) {
        MissitoRealmDbHelper.write { realm, error in
            if let error = error {
                NSLog("Failed to write contacts [RealmMissitoContact] into RealmDB: " + error.localizedDescription)
            } else if let realm = realm {
                for contact in contacts {
                    realm.create(RealmMissitoContact.self, value: contact, update: true)
                }
            } else {
                NSLog("Unknown error! RealmDB is nil")
            }
        }
    }
    
    static func getMessage(with localId: String) -> RealmMessage? {
        return MissitoRealmDbHelper.get(RealmMessage.self, String(format: "id = '%@'", localId))
    }
    
    static func setIncomingMessageStatus(_ localId: String, _ incomingStatus: RealmMessage.IncomingMessageStatus) {
        MissitoRealmDbHelper.write(RealmMessage.self, ["id" : localId, "incomingStatus": incomingStatus.rawValue], update: true)
    }
    
    static func deleteAll(_ type: Object.Type) {
        // should we lock writing into database while it removes objects?
        // from Realm docs:
        /* Realm write operations are synchronous and blocking, not asynchronous. If thread A starts a write operation,
           then thread B starts a write operation on the same Realm before thread A is finished,
           thread A must finish and commit its transaction before thread B’s write operation takes place. */
        
        DispatchQueue.global().async {
            if let db = MissitoRealmDB.shared.database() {
                let objects = db.objects(type)
                try! db.write {
                    for obj in objects {
                        db.delete(obj)
                    }
                }
            }
        }
    }

    static func createDefaultConversation(contact: RealmMissitoContact) {
        if let db = MissitoRealmDB.shared.database() {
            do {
                try db.write {
                    let conversation = RealmConversation.init(counterparts: [contact])
                    db.create(RealmConversation.self, value: conversation, update: false)
                    contact.defaultConversationId = conversation.id
                }
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }
    }
    
    static func getDefaultConversation(phone: String?, create: Bool = false) -> RealmConversation? {
        
        guard phone != nil else {
            return nil
        }
        if let db = MissitoRealmDB.shared.database(),
            let contact = db.objects(RealmMissitoContact.self).filter("phone CONTAINS '\(phone!)'").first {
            if contact.defaultConversationId == nil {
                if create {
                    createDefaultConversation(contact: contact)
                } else {
                    return nil
                }
            }
            return db.object(ofType: RealmConversation.self, forPrimaryKey: contact.defaultConversationId)
        }
        return nil
    }
    
    static func saveRealmMessage(_ message: RealmMessage) {
        let conversation = getDefaultConversation(phone: message.outgoingStatus != nil ? message.destUid : message.senderUid, create: true)
        if let db = MissitoRealmDB.shared.database() {
            do {
                try db.write {
                    db.create(RealmMessage.self, value: message, update: false)
                    // https://stackoverflow.com/questions/40592350/realm-cant-create-object-with-existing-primary-key-value
                    let savedMessage = db.object(ofType: RealmMessage.self, forPrimaryKey: message.id)
                    conversation?.lastMessage = savedMessage
                }
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }
        NotificationCenter.default.post(name: CONVERSATIONS_UPDATE, object: nil, userInfo: nil)
    }
    
    static func fetchConversation(with id: String) -> RealmConversation? {
        return fetch(type: RealmConversation.self, condition: String(format: "id = '%@'", id))?.first
    }
    
    static func fetchConversations() -> [RealmConversation] {
        if let db = MissitoRealmDB.shared.database() {
            return db.objects(RealmConversation.self).sorted(by: { (c1, c2) -> Bool in
                let t1 = c1.lastMessage?.timeSent.timeIntervalSince1970 ?? 0
                let t2 = c2.lastMessage?.timeSent.timeIntervalSince1970 ?? 0
                return t1 > t2
            })
        }
        return []
    }
    
    static func getConversationCount() -> Int {
        if let db = MissitoRealmDB.shared.database() {
            return db.objects(RealmConversation.self).count
        }
        return 0
    }
    
    // Call from within a write transcation only!
    static func updateLastMessage(chat: RealmConversation) {
        let phone = chat.counterparts[0].phone
        let predicate = NSPredicate(format: "destUid = %@ OR senderUid = %@", phone, phone)
        if let db = MissitoRealmDB.shared.database() {
            let lastMessage = db.objects(RealmMessage.self).filter(predicate).sorted(byKeyPath: "timeSent", ascending: false).first
            chat.lastMessage = lastMessage
        }
    }

}
