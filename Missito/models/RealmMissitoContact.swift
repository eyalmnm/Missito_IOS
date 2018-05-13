//
//  RealmMissitoContact.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/15/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//
//  This class represents contacts that are part of Missito community 
//  and simultaniously appear to be a part of user's phone book
//

import Foundation
import RealmSwift

final class RealmMissitoContact: Object {
    
    dynamic var firstName: String = ""
    dynamic var lastName: String = ""
    dynamic var phone: String = ""
    dynamic var wasAdded: Date? = nil
    dynamic var imageData: Data? = nil
    dynamic var defaultConversationId: String? = nil
    
    convenience init(firstName: String, lastName: String, phone: String, imageData: Data?, wasAdded: Date? = nil) {
        self.init()
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.wasAdded = wasAdded
        self.imageData = imageData
    }
    
    static func make(from: Contact) -> RealmMissitoContact {
        return RealmMissitoContact(firstName: from.firstName,
                           lastName: from.lastName,
                           phone: from.phone,
                           imageData: from.imageData,
                           wasAdded: from.wasAdded)
    }
    
    override static func primaryKey() -> String {
        return "phone"
    }
    
    func formatFullName() -> String {
        return String.init(format: "%@ %@", firstName, lastName).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
