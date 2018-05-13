//
//  MessageBody.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/3/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class MessageBody: Gloss.Decodable, Gloss.Encodable {
    
    let uniqueId: String
    let text: String?
    let typing: Typing?
    let typingStart: UInt64?
    let attach: MissitoAttachment?
    
    init(text: String?, uniqueId: String, typing: Typing? = nil, typingStart: UInt64, attach: MissitoAttachment?) {
        self.text = text
        self.uniqueId = uniqueId
        self.typing = typing
        self.typingStart = typingStart
        self.attach = attach
    }
    
    init?(json: JSON) {
        self.text = "text" <~~ json
        self.uniqueId = "uniqueId" <~~ json ?? ""
        self.typing = Typing(rawValue: "typing" <~~ json ?? "")
        self.typingStart = "typingStart" <~~ json
        self.attach = "attach" <~~ json
    }
    
    func isTyping() -> Bool {
        if let typing = typing {
            return typing == .on
        }
        return false
    }
    
    func isValidTyping() -> Bool {
        if let typingStart = typingStart {
            return isTyping() && (Int64(NSDate().timeIntervalSince1970) - Int64(typingStart)/1000) < 3
        }
        return false
    }
    
    func toJSON() -> JSON? {
        return jsonify([
            "text" ~~> text,
            "uniqueId" ~~> uniqueId,
            "typing" ~~> typing?.rawValue,
            "typingStart" ~~> typingStart,
            "attach" ~~> attach
            ])
    }
    
    enum Typing: String {
        case on = "on" //, off = "off"
    }
    
}
