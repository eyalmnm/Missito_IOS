//
//  Contact.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/24/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class Contact: Hashable, Equatable {

    let firstName: String
    let lastName: String
    let fullName: String
    let imageData: Data?
    var phone: String
    var wasAdded: Date? = nil
    var unreadCount = 0
    
    init(_ firstName: String, _ lastName: String, _ phone: String, _ imageData: Data?, _ wasAdded: Date? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.wasAdded = wasAdded
        self.imageData = imageData
        fullName = String(format: "%@ %@", firstName, lastName).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func isNew() -> Bool {
        guard let date = wasAdded else {
            return false
        }
        
        let firstContactsCommitDate = DefaultsHelper.getFirstContactsCommitDate() ?? Date()
        
        return date > firstContactsCommitDate.addingTimeInterval(60.0) && Date() < date.addHours(12)
    }
    
    static func make(from missitoContact: RealmMissitoContact) -> Contact {
        return Contact(missitoContact.firstName, missitoContact.lastName, missitoContact.phone,
                       missitoContact.imageData, missitoContact.wasAdded)
    }
    
    public var hashValue: Int {
        var result = 11
        result = 37 &* result &+ firstName.hashValue
        result = 37 &* result &+ lastName.hashValue
        result = 37 &* result &+ phone.hashValue
        result = 37 &* result &+ (wasAdded == nil ? 0 : wasAdded!.hashValue)
        return result
    }
    
    static func ==(lhs: Contact, rhs: Contact) -> Bool {
        return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName && lhs.phone == rhs.phone
    }
    
    func formatFullName() -> String {
        return fullName
    }

}
