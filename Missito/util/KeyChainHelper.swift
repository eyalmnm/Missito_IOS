//
//  KeyChainHelper.swift
//  Missito
//
//  Created by Alex Gridnev on 5/2/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import KeychainSwift

class KeyChainHelper {
    
    private static let USER_ID_KEY = "user_id"
    private static let USER_TOKEN_KEY = "user_token"
    private static let REALM_KEY_KEY = "realm_key"
    private static let INSTALL_ID_KEY = "install_id"
    
    //Store database Key if doesn't exist.
    private static let keychain = { () -> KeychainSwift in 
        let kc = KeychainSwift()
        kc.synchronizable = false
        return kc
    }()
    
    static func getUserId() -> String? {
        return keychain.get(USER_ID_KEY)
    }
    
    static func getUserToken() -> String? {
        return keychain.get(USER_TOKEN_KEY)
    }
    
    static func saveUserId(_ userId: String) -> Bool {
        return keychain.set(userId, forKey: USER_ID_KEY)
    }
    
    static func saveUserToken(_ token: String) -> Bool {
        return keychain.set(token, forKey: USER_TOKEN_KEY)
    }

    static func removeUserId() -> Bool {
        return keychain.delete(USER_ID_KEY)
    }
    
    static func removeUserToken() -> Bool {
        return keychain.delete(USER_TOKEN_KEY)
    }
    
    static func removeRealmKeys() -> Bool {
        return keychain.delete(REALM_KEY_KEY)
    }

    static func getRealmKey(userId: String) -> Data? {
        let keyDict = getDictionary(key: REALM_KEY_KEY)
        return keyDict?[userId]?.dataFromBase64()
    }

    static func saveRealmKey(userId: String, key: Data) -> Bool {
        var keyDict = getDictionary(key: REALM_KEY_KEY)
        if keyDict == nil {
            keyDict = [:]
        }
        keyDict![userId] = key.base64EncodedString()
        return save(dictionary: keyDict!, key: REALM_KEY_KEY)
    }
    
    private static func getDictionary(key: String) -> [String : String]? {
        do {
            guard let jsonData = keychain.getData(key) else {
                return nil
            }
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            return decoded as? [String:String]
        } catch {
            NSLog("getDictionary failed: %@", error.localizedDescription)
        }
        return nil
    }

    private static func save(dictionary: [String : String], key: String) -> Bool {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
            return keychain.set(jsonData, forKey: key)
        } catch {
            NSLog("getDictionary failed: %@", error.localizedDescription)
        }
        return false
    }
    
    static func cleanKeychain() {
        removeUserAuthData()
        _ = removeRealmKeys()
    }

    static func removeUserAuthData() {
        _ = removeUserId();
        _ = removeUserToken();
    }

    static func saveUserAuthData(userId: String, token: String) {
        _ = saveUserId(userId)
        _ = saveUserToken(token)
    }

    static func saveInstallId(_ id: String) {
        keychain.set(id, forKey: INSTALL_ID_KEY)
    }
    
    static func getInstallId() -> String? {
        return keychain.get(INSTALL_ID_KEY)
    }
}
