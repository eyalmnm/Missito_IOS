//
//  ContactsManager.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/31/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Contacts

class ContactsManager {
    
    static let CONTACTS_READY_NOTIF = NSNotification.Name(rawValue: "contacts_ready")
    
    static var contactsReady = false
    static var accessAllowed = false
    static var contacts: [Contact] = []
    static var contactsByPhone: [String: Contact] = [:]
    
    static func updateMissitoContacts() {
        var missitoPhones: Set<String> = []
        if let missitoContacts = MissitoRealmDbHelper.getMissitoContacts(), !missitoContacts.isEmpty {
            missitoPhones = Set<String>(missitoContacts.map { contact -> String in
                contact.phone
            })
        }
        
        let contactsToSave = contacts.filter { (contact) -> Bool in
            return ContactsStatusManager.missitoPhones.contains(contact.phone) &&
                !missitoPhones.contains(contact.phone)
        }.map { (contact) -> RealmMissitoContact in
            contact.wasAdded = Date()
            return RealmMissitoContact.make(from: contact)
        }
        
        MissitoRealmDbHelper.saveMissitoContacts(contactsToSave)
    }
    
    static func fetchContacts() {
        contactsReady = false
        contacts = []
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch authorizationStatus {
        case .authorized:
            accessAllowed = true
            requestContactsList()
        case .denied, .notDetermined:
            CNContactStore().requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                self.accessAllowed = access
                if access {
                    self.requestContactsList()
                } else {
                    self.contactsReady = true
                }
            })
        default:
            accessAllowed = false
            contactsReady = true
        }
    }
    
    private static func requestContactsList() {
        
        DispatchQueue.global().async(execute: { () -> Void in
            var contacts: [Contact] = []
            var contactsByPhone: [String: Contact] = [:]

            let contactStore = CNContactStore()
            
            let keysToFetch = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactEmailAddressesKey,
                CNContactPhoneNumbersKey,
                CNContactImageDataAvailableKey,
                CNContactThumbnailImageDataKey] as [Any]
            
            // Get all the containers
            var allContainers: [CNContainer] = []
            
            do {
                allContainers = try contactStore.containers(matching: nil)
            } catch {
                print("Error fetching containers")
            }
            
            // Iterate all containers and append their contacts to our results array
            for container in allContainers {
                
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                
                do {
                    
                    let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                    var allPhones: Set<String> = Set()
                    for contact in containerResults {
                        let phones = self.getPhoneNumbers(contact)
                        for phone in phones {
                            if phone != CoreServices.authService?.userId {
                                if !allPhones.contains(phone) {
                                    allPhones.insert(phone)
                                    let contact = Contact(contact.givenName, contact.familyName, phone, contact.thumbnailImageData)
                                    contacts.append(contact)
                                    contactsByPhone[phone] = contact
                                }
                            }
                        }
                    }
                    contacts = contacts.sorted(by: { (cn1, cn2) -> Bool in
                        cn1.firstName == cn2.firstName ? cn1.lastName < cn2.lastName : cn1.firstName < cn2.firstName
                    })
                    
                } catch {
                    print("Error fetching results for container")
                }
                
            }
            
            DispatchQueue.main.async {
                self.contacts = contacts
                self.contactsByPhone = contactsByPhone
                self.contactsReady = true
                self.synchronizeContacts()
                self.updateMissitoContacts()
                NotificationCenter.default.post(name: ContactsManager.CONTACTS_READY_NOTIF, object: nil, userInfo: nil)
            }
        })
    }
    
    private static func synchronizeContacts() {
        guard CoreServices.authService?.authState == .loggedIn else {
            return
        }
        DispatchQueue.global().async {
            let savedPhones = Set(Utils.getStoredContactsPhones())
            let allPhones = Set(self.getAllPhones())
            
            let phones = allPhones.subtracting(savedPhones)
            if !phones.isEmpty {
                DispatchQueue.main.async {
                    self.addContacts(phones: Array(phones))
                }
            }
        }
    }
    
    private static func addContacts(phones: [String]) {
        // Get array of Contacts from phone numbers and extract info for request
        let filteredContacts = phones.flatMap({contactsByPhone[$0]})
        let contacts = filteredContacts.map({ContactsUpdateMessage.ContactInfo(phone: Utils.removePlusFrom(phone: $0.phone), firstName: $0.firstName, lastName: $0.lastName)})
        
        APIRequests.addContacts(contacts: ContactsUpdateMessage(contacts: contacts)) {
            (error) in
            if let error = error {
                NSLog("Could not add contacts: " + error.localizedDescription)
            } else {
                NSLog("Contacts added successfully")
                MissitoRealmDbHelper.writePhones(phones)
            }
        }
    }
    
    static func getPhoneNumbers(_ contact: CNContact) -> [String] {
        var phones: [String] = []
        for phone in contact.phoneNumbers {
            if let ph = Utils.parseAndValidateNumber(phone.value.stringValue) {
                phones.append(ph)
            }
        }
        return phones
    }
    
    static func getContact(phone: String) -> Contact? {
        return contacts.first(where: { contact -> Bool in
            contact.phone == phone
        })
    }
    
    static func getAllPhones() -> [String] {
        var phones: [String] = []
        for contact in contacts {
            phones.append(contact.phone)
        }
        return phones
    }
    
}
