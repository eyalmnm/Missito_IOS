//
//  swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//
//  This class represents attachment type that is sent with a message inside one chat
//

import Foundation
import RealmSwift
import Contacts

class RealmAttachmentContact: Object {
    
    dynamic var name: String? = ""
    dynamic var surname: String? = ""
    dynamic var notes: String? = ""
    dynamic var avatar: String?
    var phones = List<RealmString>()
    var emails = List<RealmString>()
    
    convenience init(_ contact: CNContact) {
        self.init()
        name = contact.givenName
        surname = contact.familyName
        notes = contact.note
        for number in contact.phoneNumbers {
            let phone = RealmString.make(from: number.value.stringValue)
            phones.append(phone)
        }
        for email in contact.emailAddresses {
            let email = RealmString.make(from: email.value as String)
            emails.append(email)
        }
        
        if let imageData = contact.imageData {
            if let base64Str = UIImage(data: imageData)?.toBase64(UIImage.UTI_JPEG, quality: CGFloat(0.7)) {
                avatar = base64Str
            }
        }
    }
    
    convenience init(name: String?, surname: String?, avatar: String?, phones: List<RealmString>, emails: List<RealmString>, notes: String?) {
        self.init()
        self.name = name
        self.surname = surname
        self.avatar = avatar
        self.phones = phones
        self.emails = emails
        self.notes = notes
    }
    
    func formatFullName() -> String {
        return ((name ?? "") + " " + (surname ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func cascadeDelete(_ realm: Realm) {
        for phone in phones {
            realm.delete(phone)
        }
        for email in emails {
            realm.delete(email)
        }
        realm.delete(self)
    }
    
    func toCNContact() -> CNContact {
        let contact = CNMutableContact()
        
        var phoneNumbers: [CNLabeledValue<CNPhoneNumber>] = []
        for x in phones {
            phoneNumbers.append(CNLabeledValue(label: CNLabelHome, value: CNPhoneNumber(stringValue: x.stringValue)))
        }
        contact.phoneNumbers = phoneNumbers
        
        var cnemails: [CNLabeledValue<NSString>] = []
        for x in emails {
            cnemails.append(CNLabeledValue(label: CNLabelHome, value: x.stringValue as NSString))
        }
        contact.emailAddresses = cnemails
        
        contact.givenName = name ?? ""
        contact.familyName = surname ?? ""
        contact.note = notes ?? ""
        return contact
    }
}
