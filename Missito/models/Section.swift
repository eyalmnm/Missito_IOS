//
//  Section..swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/29/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class Section: Hashable, Equatable {
    
    var type: String
    var contacts: [Contact] = []
    
    init(type: String = "") {
        self.type = type
    }
    
    func sortContacts() {
        contacts.sort(by: { (contact1, contact2) -> Bool in
            contact1.firstName == contact2.firstName ? contact1.lastName < contact2.lastName : contact1.firstName < contact2.firstName
        })
    }
    
    public static func ==(lhs: Section, rhs: Section) -> Bool {
        return lhs.type == rhs.type && lhs.contacts == rhs.contacts
    }
    
    public var hashValue: Int { return type.hashValue }
}
