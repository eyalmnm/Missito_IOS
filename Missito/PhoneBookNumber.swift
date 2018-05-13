//
//  PhoneBookNumber.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/25/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

final class PhoneBookNumber: Object {

    dynamic var phone: String = ""
    
    convenience init(phone: String) {
        self.init()
        self.phone = phone
    }
    
}
