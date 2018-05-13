//
//  ContactsStatusManager.swift
//  Missito
//
//  Created by Alex Gridnev on 6/1/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class ContactsStatusManager {
    
    static let CONTACT_STATUS_UPDATE_NOTIF = NSNotification.Name(rawValue: "status_key")
    static let DATA_KEY = "data"
    static let BLOCKED_PHONE_KEY = "blocked_phone"
    static let UNBLOCKED_PHONE_KEY = "unblocked_phone"
    static let MUTE_PHONE_KEY = "mute_phone"
    static let UNMUTE_PHONE_KEY = "unmute_phone"
    
    private static var phoneStatus: [String : ContactStatus] = [:]
    static var missitoPhones: Set<String> = Set()
    static var deviceIds: [String : Int] = [:]
    
    static func setAllOffline() {
        var phonesOnline: [OfflineContact] = []
        for phone in phoneStatus.keys {
            if (phoneStatus[phone]?.isOnline)! {
                phoneStatus[phone]?.isOnline = false
                phonesOnline.append(OfflineContact(phone, UInt64(NSDate().timeIntervalSince1970), deviceIds[phone] ?? 0))
            }
        }
        
        if phonesOnline.count > 0 {
            NotificationCenter.default.post(name: CONTACT_STATUS_UPDATE_NOTIF, object: nil, userInfo: [DATA_KEY : ContactsStatusUpdate(toOffline: phonesOnline)])
        }
    }
    
    static func update(_ update: ContactsStatusUpdate) {
		missitoPhones.formUnion(update.online.map {$0.userId})
        missitoPhones.formUnion(update.offline.map({ (offlineContact) -> String in
            offlineContact.userId
        }))
        missitoPhones.formUnion(update.blocked.map {$0.userId})
        missitoPhones.formUnion(update.muted.map {$0.userId})
        
        for phone in update.online {
            getStatus(phone: phone.userId).isOnline = true
            deviceIds[phone.userId] = phone.deviceId
        }
        for offlineContact in update.offline {
            getStatus(phone: offlineContact.userId).isOnline = false
            getStatus(phone: offlineContact.userId).lastSeen = offlineContact.lastSeen
            deviceIds[offlineContact.userId] = offlineContact.deviceId
        }
        for phone in update.blocked {
            getStatus(phone: phone.userId).isBlocked = true
            deviceIds[phone.userId] = phone.deviceId
        }
        for phone in update.muted {
            getStatus(phone: phone.userId).isMuted = true
            deviceIds[phone.userId] = phone.deviceId
        }
        ContactsManager.updateMissitoContacts()
        if DefaultsHelper.getFirstContactsCommitDate() == nil {
            DefaultsHelper.saveFirstContactsCommitDate(Date())
        }
        NotificationCenter.default.post(name: CONTACT_STATUS_UPDATE_NOTIF, object: nil, userInfo: [DATA_KEY : update])
    }
    
    static func blockUser(phone: String) {
        getStatus(phone: phone).isBlocked = true
        getStatus(phone: phone).isMuted = false
        NotificationCenter.default.post(name: CONTACT_STATUS_UPDATE_NOTIF, object: nil, userInfo: [BLOCKED_PHONE_KEY : phone])
    }
    
    static func unblockUser(phone: String) {
        getStatus(phone: phone).isBlocked = false
        NotificationCenter.default.post(name: CONTACT_STATUS_UPDATE_NOTIF, object: nil, userInfo: [UNBLOCKED_PHONE_KEY : phone])
    }
    
    static func muteUser(phone: String) {
        getStatus(phone: phone).isMuted = true
        NotificationCenter.default.post(name: CONTACT_STATUS_UPDATE_NOTIF, object: nil, userInfo: [MUTE_PHONE_KEY : phone])
    }
    
    static func unmuteUser(phone: String) {
        getStatus(phone: phone).isMuted = false
        NotificationCenter.default.post(name: CONTACT_STATUS_UPDATE_NOTIF, object: nil, userInfo: [UNMUTE_PHONE_KEY : phone])
    }

    static func getStatus(phone: String) -> ContactStatus {
        if phoneStatus[phone] == nil {
            phoneStatus[phone] = ContactStatus()
        }
        return phoneStatus[phone]!
    }
    
    static func contains(phone: String) -> Bool {
        return phoneStatus[phone] != nil
    }
    
    static func revertUserBlockStatus(phone: String, completion: @escaping (APIError?, Bool?)->()) {
        let willBlock = !getStatus(phone: phone).isBlocked
        let block: [String] = willBlock ? [phone] : []
        let unblock: [String] = willBlock ? [] : [phone]
        APIRequests.updateContactsStatus(block: block, normal: unblock, muted: [], { (error) in
            if let error = error {
                NSLog("Contact %@ %@ failed: %@", phone, willBlock ? "block" : "unblock", error.localizedDescription)
                completion(error, nil)
            } else {
                if willBlock {
                    blockUser(phone: phone)
                } else {
                    unblockUser(phone: phone)
                }
                NSLog("isBlocked=" + String(willBlock))
                completion(nil, willBlock)
            }
        })
    }
    
}
