//
//  NextOTPKIdData.swift
//  Missito
//
//  Created by Alex Gridnev on 5/17/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class NextOTPKIdData: Object {
    
    dynamic var id = 1            // constant, we store only one object
    
    dynamic var nextId = -1
    
    convenience init(nextId: Int) {
        self.init()
        self.nextId = nextId
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
