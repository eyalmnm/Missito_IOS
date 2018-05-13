//
//  ContactsUpdateMessage.swift
//  Missito
//
//  Created by Alex Gridnev on 5/24/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

struct ContactsUpdateMessage: Encodable {
    
    let contacts: [ContactInfo]
    
    struct ContactInfo: Encodable {
        let phone: String
        let firstName: String
        let lastName: String
    }
}
