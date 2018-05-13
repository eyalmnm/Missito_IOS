//
//  LocalIdentityData.swift
//  Missito
//
//  Created by Alex Gridnev on 5/16/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class LocalIdentityData: Object {
    
    dynamic var id = 1            // constant, we store only one object

    dynamic var publicKey = NSData()
    dynamic var privateKey = NSData()
    
    convenience init(publicKey: NSData, privateKey: NSData) {
        self.init()
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
