//
//  TextMessages.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/25/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RealmMessage: Object {
    
    dynamic var id: String = ""
    dynamic var uniqueId: String = ""
    dynamic var serverMsgId: String? = ""
    dynamic var groupId: String? = ""
    dynamic var threadId: String? = ""
    dynamic var timeSent: Date = Date()
    dynamic var senderUid: String? = ""
    dynamic var senderDeviceId: Int = 0
    dynamic var destUid: String? = ""
    dynamic var destDeviceId: Int = 0
    dynamic var msg: String? = ""
    dynamic var contentType: String? = ""
    dynamic var incomingStatusStr: String? = ""
    dynamic var outgoingStatusStr: String? = ""
    dynamic var attachment: RealmAttachment?
    
    var incomingStatus: IncomingMessageStatus? {
        get {
            return incomingStatusStr == nil ? nil : IncomingMessageStatus(rawValue: incomingStatusStr!)
        }
        set {
            incomingStatusStr = newValue?.rawValue
        }
    }
    
    var outgoingStatus: OutgoingMessageStatus? {
        get {
            return outgoingStatusStr == nil ? nil : OutgoingMessageStatus(rawValue: outgoingStatusStr!)
        }
        set {
            outgoingStatusStr = newValue?.rawValue
        }
    }
    
    convenience init(serverMsgId: String?, groupId: String?, threadId: String?, timeSent: UInt64?,
                     senderUid: String?, senderDeviceId: Int, destUid: String?, destDeviceId: Int,
                     msg: String?, contentType: String?,
                     incomingStatus: IncomingMessageStatus?, outgoingStatus: OutgoingMessageStatus?,
                     attachment: RealmAttachment? = nil) {
        self.init()
        self.id = UUID().uuidString
        self.uniqueId = UUID().uuidString
        self.serverMsgId = serverMsgId
        self.groupId = groupId
        self.threadId = threadId
        self.timeSent = Date.init(timeIntervalSince1970: TimeInterval(timeSent ?? 0))
        self.senderUid = senderUid
        self.senderDeviceId = senderDeviceId
        self.destUid = destUid
        self.destDeviceId = destDeviceId
        self.msg = msg
        self.contentType = contentType
        self.incomingStatus = incomingStatus
        self.outgoingStatus = outgoingStatus
        self.attachment = attachment
    }
    
    convenience init(incomingMessage: IncomingMessage, body: MessageBody, incomingStatus: IncomingMessageStatus?, destUid: String?, destDeviceId: Int) {
        self.init()
        
        self.id = UUID().uuidString
        self.uniqueId = body.uniqueId
        fill(incomingMessage: incomingMessage, body: body, incomingStatus: incomingStatus, destUid: destUid, destDeviceId: destDeviceId)
    }
    
    func fill(incomingMessage: IncomingMessage, body: MessageBody, incomingStatus: IncomingMessageStatus?, destUid: String?, destDeviceId: Int) {
        self.serverMsgId = incomingMessage.serverMsgId
        self.timeSent = Date.init(timeIntervalSince1970: TimeInterval(incomingMessage.timeSent))
        self.senderUid = incomingMessage.senderUid
        self.senderDeviceId = incomingMessage.senderDeviceId
        self.destUid = destUid
        self.destDeviceId = destDeviceId
        self.contentType = incomingMessage.msgType
        self.attachment = RealmAttachment.make(from: body.attach)
        self.msg = body.text
        self.id = UUID().uuidString
        self.uniqueId = body.uniqueId
        self.incomingStatus = incomingStatus
        self.outgoingStatus = nil
    }
    
    func getType() -> MessageType {
        var type = MessageType.text
        if let attach = attachment {
            if attach.images.count > 0 {
                type = .image
            }
            if attach.contacts.count > 0 {
                type = .contact
            }
            if attach.locations.count > 0 {
                type = .geo
            }
            if attach.audio.count > 0 {
                type = .audio
            }
            if attach.video.count > 0 {
                type = .video
            }
        }
        return type
    }
    
    static func empty() -> RealmMessage {
        return RealmMessage(serverMsgId: nil, groupId: nil, threadId: nil, timeSent: nil,
                            senderUid: nil, senderDeviceId: 0, destUid: nil, destDeviceId: 0, msg: nil, contentType: nil,
                           incomingStatus: nil, outgoingStatus: nil)
    }
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    public func cascadeDelete(_ realm: Realm) {
        attachment?.cascadeDelete(realm);
        realm.delete(self)
    }
    
    enum OutgoingMessageStatus: String {
        case outgoing = "outgoing"
        case sent = "sent"
        case delivered = "received"
        case seen = "seen"
    }
    
    enum IncomingMessageStatus: String {
        case received = "received"
        case receivedAck = "rcv_ack"
        case seenAck = "seen_ack"
        case seen = "seen"
        case failed = "failed"
    }

}
