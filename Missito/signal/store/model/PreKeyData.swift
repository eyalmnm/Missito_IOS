//
//  PreKeyData.swift
//  Missito
//
//  Created by Alex Gridnev on 5/17/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class PreKeyData: Object {
    
    dynamic var id = -1
    
    dynamic var keyRecord = NSData()
    
    convenience init(id: Int, keyRecord: NSData) {
        self.init()
        self.id = id
        self.keyRecord = keyRecord
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
