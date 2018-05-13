//
//  RealmDbHelper.swift
//  Missito
//
//  Created by Alex Gridnev on 5/16/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

@objc class RealmDbHelper: NSObject {
    
    static func saveLocalIdentityData(_ data: LocalIdentityData) {
        saveObject(data)
    }
    
    static func getLocalIdentityData() -> LocalIdentityData? {
        return getFirstObject()
    }

    static func saveRegistrationIdData(_ data: RegistrationIdData) {
        saveObject(data)
    }
    
    static func getRegistrationIdData() -> RegistrationIdData? {
        return getFirstObject()
    }
    
    static func saveRemoteIdentityData(_ data: RemoteIdentityData) {
        saveObject(data)
    }
    
    static func getRemoteIdentityData(key: String) -> RemoteIdentityData? {
        return getObjectForKey(key: key)
    }
    
    static func saveLocalSignedPreKeyData(_ data: LocalSignedPreKeyData) {
        saveObject(data)
    }
    
    static func getLocalSignedPreKeyData(id: Int) -> LocalSignedPreKeyData? {
        return getObjectForKey(key: id)
    }
    
    static func removeLocalSignedPreKeyData(id: Int) {
        _ = removeObjectWithKey(type: LocalSignedPreKeyData.self, key: id)
    }
    
    static func saveNextOTPKIdData(_ data: NextOTPKIdData) {
        saveObject(data)
    }
    
    static func getNextOTPKIdData() -> NextOTPKIdData? {
        return getFirstObject()
    }

    static func savePreKeyData(_ data: PreKeyData) {
        saveObject(data)
    }
    
    static func getPreKeyData(id: Int) -> PreKeyData? {
        return getObjectForKey(key: id)
    }
    
    static func getPreKeyArray(startId: Int, count: Int) -> [PreKeyData] {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "id >= %d AND id < %d", startId, startId + count)
        return Array(realm.objects(PreKeyData.self).filter(predicate).sorted(byKeyPath: "id", ascending: true))
    }
    
    static func removePreKeyData(id: Int) {
        _ = removeObjectWithKey(type: PreKeyData.self, key: id)
    }
    
    static func saveSessionData(_ data: SessionData) {
        saveObject(data)
    }
    
    static func getSessionData(key: String) -> SessionData? {
        return getObjectForKey(key: key)
    }
    
    static func removeSessionData(key: String) -> Int {
        return removeObjectWithKey(type: PreKeyData.self, key: key) ? 1 : 0
    }

    static func getSubDeviceSessions(name: String) -> [SessionData] {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "name = %@", name)
        return Array(realm.objects(SessionData.self).filter(predicate))
    }

    static func removeAllSessionData(name: String) -> Int {
        var result = 0
        let realm = try! Realm()
        try! realm.write {
            let predicate = NSPredicate(format: "name = %@", name)
            let objects = realm.objects(SessionData.self).filter(predicate)
            result = objects.count
            realm.delete(objects)
        }
        return result
    }


    // MARK: generic methods
    
    static func saveObject(_ data: Object) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(data, update: true)
        }
    }
    
    static func getFirstObject<T: Object>() -> T? {
        let realm = try! Realm()
        return realm.objects(T.self).first
    }

    static func getObjectForKey<T: Object, K>(key: K) -> T? {
        let realm = try! Realm()
        return realm.object(ofType: T.self, forPrimaryKey: key)
    }
    
    static func removeObjectWithKey<T: Object, K>(type: T.Type, key: K) -> Bool {
        var result = false
        let realm = try! Realm()
        try! realm.write {
            if let obj = realm.object(ofType: T.self, forPrimaryKey: key) {
                result = true
                realm.delete(obj)
            }
        }
        return result
    }
    
}
