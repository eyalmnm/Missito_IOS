//
//  ContactsStatusUpdate.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/30/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Gloss

@objc final class StatusMessage: NSObject, Gloss.Decodable {
	let msgType: String
	let msg: ContactsStatusUpdate?
	
	init?(json: JSON) {
		guard let msgType: String = "msgType" <~~ json else {
				return nil
		}
		
		self.msgType = msgType
		msg = "msg" <~~ json
        if msg == nil && msgType != "logout" {
            return nil
        }
	}

}

final class ContactsStatusUpdate: NSObject, Gloss.Decodable {
    
    var online: [ContactEntry]
    var offline: [OfflineContact]
    var blocked: [ContactEntry]
    var muted: [ContactEntry]
    
    init(json: JSON) {
        self.online = ("online" <~~ json) ?? []
        self.offline = ("offline" <~~ json) ?? []
        self.blocked = ("blocked" <~~ json) ?? []
        self.muted = ("muted" <~~ json) ?? []
    }
    
    init(toOffline: [OfflineContact]) {
        offline = toOffline
        online = []
        blocked = []
        muted = []
    }
    
    final class ContactEntry: NSObject, Gloss.Decodable {
        
        let userId: String
        let deviceId: Int
        
        init?(json: JSON) {
            guard let userId: String = ("userId") <~~ json,
                let deviceId: Int = "deviceId" <~~ json else {
                    return nil
            }
            
            self.userId = Utils.fixPhoneFormat(userId)
            self.deviceId = deviceId
        }
    }
}
