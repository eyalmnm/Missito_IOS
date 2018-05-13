//
//  RegistrationIdData.swift
//  Missito
//
//  Created by Alex Gridnev on 5/16/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RegistrationIdData: Object {
    
    dynamic var id = 1            // constant, we store only one object
    
    dynamic var registrationId = -1
    
    convenience init(registrationId: Int) {
        self.init()
        self.registrationId = registrationId
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
