//
//  DefaultsHelper.swift
//  Missito
//
//  Created by Alex Gridnev on 5/18/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

@objc class DefaultsHelper: NSObject {
    
    private static let REPORT_KEYS_FLAG_KEY = "report_keys_flag"
    private static let LAST_REPORTED_OTPK_ID_KEY = "last_reported_otpk_id"
    private static let LAST_CODE_SEND_TIME_KEY = "last_code_send_time"
    private static let FIRST_CONTACTS_COMMIT_DATE_KEY = "first_contacts_commit_date"
    private static let LAST_INVITES_NOTIFICATION_TIME = "last_invites_notification_time"
    private static let INSTALL_ID_KEY = "install_id_default"
    private static let DEVICE_ID_KEY = "_device_id"
    private static let PRIVACY_ONLINE_STATUS = "privacy_online_status"
    private static let USER_NAME_KEY = "user_name"

    private static func getKey(_ baseKey: String) -> String {
        return baseKey + (CoreServices.authService?.userId ?? "default");
    }
    
    static func saveReportKeysFlag(_ flag: Bool) {
        UserDefaults.standard.set(flag, forKey: getKey(REPORT_KEYS_FLAG_KEY))
    }

    static func getReportKeysFlag() -> Bool {
        return UserDefaults.standard.bool(forKey: getKey(REPORT_KEYS_FLAG_KEY))
    }
    
    static func saveLastReportedOtpkId(_ id: Int) {
        UserDefaults.standard.set(id, forKey: getKey(LAST_REPORTED_OTPK_ID_KEY))
    }
    
    static func getLastReportedOtpkId() -> Int {
        return UserDefaults.standard.integer(forKey: getKey(REPORT_KEYS_FLAG_KEY))
    }

    static func saveLastCodeSendTime(_ time: Int64) {
        UserDefaults.standard.set(time, forKey: getKey(LAST_CODE_SEND_TIME_KEY))
    }
    
    static func getLastCodeSendTime() -> Int64 {
        return (UserDefaults.standard.object(forKey: getKey(LAST_CODE_SEND_TIME_KEY)) as? Int64) ?? 0
    }

    static func saveFirstContactsCommitDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: getKey(FIRST_CONTACTS_COMMIT_DATE_KEY))
    }
    
    static func getFirstContactsCommitDate() -> Date? {
        return UserDefaults.standard.object(forKey: getKey(FIRST_CONTACTS_COMMIT_DATE_KEY)) as? Date
    }
    
    static func setLastInvitesNotificationTime(_ time: Double = NSDate().timeIntervalSince1970) {
        return UserDefaults.standard.set(time, forKey: LAST_INVITES_NOTIFICATION_TIME)
    }
    
    static func getLastInvitesNotificationTime() -> TimeInterval {
        return UserDefaults.standard.double(forKey: LAST_INVITES_NOTIFICATION_TIME)
    }

    static func saveInstallId(_ id: String) {
        UserDefaults.standard.set(id, forKey: INSTALL_ID_KEY)
    }
    
    static func getInstallId() -> String? {
        return UserDefaults.standard.string(forKey: INSTALL_ID_KEY)
    }
    
    static func getDeviceId(`for` phoneNumber: String) -> Int {
        return UserDefaults.standard.integer(forKey: phoneNumber + DEVICE_ID_KEY)
    }
    
    static func saveDeviceId(`for` phoneNumber: String, _ deviceId: Int) {
        UserDefaults.standard.set(deviceId, forKey: phoneNumber + DEVICE_ID_KEY)
    }
    
    static func getPrivacyOnlineStatusDate() -> TimeInterval {
        return UserDefaults.standard.double(forKey: PRIVACY_ONLINE_STATUS)
    }
    
    static func setPrivacyOnlineStatusDate() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: PRIVACY_ONLINE_STATUS)
    }
    
    static func saveUserName(_ name: String) {
        UserDefaults.standard.set(name, forKey: USER_NAME_KEY)
    }
    
    static func getUserName() -> String? {
        return UserDefaults.standard.string(forKey: USER_NAME_KEY)
    }
}
