//
//  MissitoContact.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

// Attachment

import Foundation
import Gloss

final class MissitoContact: Gloss.Decodable, Gloss.Encodable {
    
    let name: String?
    let surname: String?
    let notes: String?
    let avatar: String?
    let phones: [String]?
    let emails: [String]?

    init?(name: String?, surname: String?, notes: String?, avatar: String?, phones: [String]?, emails: [String]?) {
        self.name = name
        self.surname = surname
        self.notes = notes
        self.avatar = avatar
        self.phones = phones
        self.emails = emails
        if isEmpty() {
            return nil
        }
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        name = "name" <~~ json
        surname = "surname" <~~ json
        phones = "phones" <~~ json
        notes = "size" <~~ json
        avatar = "avatar" <~~ json
        emails = "emails" <~~ json
        if isEmpty() {
            return nil
        }
    }
    
    func isEmpty() -> Bool {
        return name == nil && surname == nil && notes == nil && avatar == nil && phones == nil && emails == nil
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "name" ~~> self.name,
            "surname" ~~> self.surname,
            "notes" ~~> self.notes,
            "avatar" ~~> self.avatar,
            "phones" ~~> self.phones,
            "emails" ~~> self.emails
            ])
    }
    
}
