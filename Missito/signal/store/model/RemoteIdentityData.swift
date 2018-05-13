//
//  RemoteIdentityData.swift
//  Missito
//
//  Created by Alex Gridnev on 5/17/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RemoteIdentityData: Object {
    
    dynamic var id = ""
    
    dynamic var key = NSData()
    dynamic var name = ""
    dynamic var deviceId = -1
    
    convenience init(key: NSData, name: String, deviceId: Int) {
        self.init()
        self.key = key
        self.name = name
        self.deviceId = deviceId
        self.id = RemoteIdentityData.calcId(name: name, deviceId: deviceId)
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func calcId(name: String, deviceId: Int) -> String {
        return name + "_" + String(deviceId)
    }
}
