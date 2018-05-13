//
//  ContactsDataManager.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/25/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import libPhoneNumber_iOS

class ContactsDataManager {

    let isMissitoType: Bool
    var originalDatasource: [Section] = []
    var datasource: [Section] = []
    var sectionsByChar: [Character:Section] = [:]
    var phoneContact: [String:Contact] = [:]
    var phoneSection: [String:Section] = [:]
    
    init(isMissitoType: Bool = true) {
        self.isMissitoType = isMissitoType
    }
    
    func updateContactsStatus(online: [String], offline: [OfflineContact], blocked: [String], unblocked: [String]) {
        guard !datasource.isEmpty && isMissitoType else {
            return
        }
        
        var sectionsToSort: Set<Section> = Set()
        
        for phone in online {
            var onlineContact: Contact?
            if let contact = phoneContact[phone] {
                if let section = phoneSection[phone], section.type != "ONLINE", section.type != "BLOCKED" {
                    section.contacts.remove(contact)
                } else {
                    continue
                }
                onlineContact = contact
            } else if let contact = ContactsManager.getContact(phone: phone) {
                phoneContact[phone] = contact
                onlineContact = contact
            }
            if let onlineContact = onlineContact {
                let section = (onlineContact.isNew() ? datasource[0] : datasource[1])
                section.contacts.append(onlineContact)
                phoneSection[phone] = section
                sectionsToSort.insert(section)
            }
        }
        
        for offlineContact in offline {
            let phone = offlineContact.userId
            if let contact = phoneContact[phone] {
                if let section = phoneSection[phone], section.type == "ONLINE", section.type != "BLOCKED" {
                    section.contacts.remove(contact)
                    if let newSection = sectionsByChar[getFirstChar(contact: contact)] {
                        newSection.contacts.append(contact)
                        phoneSection[phone] = newSection
                        sectionsToSort.insert(newSection)
                    }
                }
            }
        }
        
        for phone in blocked {
            if let contact = phoneContact[phone] {
                if let section = phoneSection[phone], section.type != "BLOCKED" {
                    section.contacts.remove(contact)
                    let blockedSection = datasource.last!
                    blockedSection.contacts.append(contact)
                    phoneSection[phone] = blockedSection
                    sectionsToSort.insert(blockedSection)
                }
            }
        }
        
        for phone in unblocked {
            if let contact = phoneContact[phone] {
                if let section = phoneSection[phone], section.type == "BLOCKED" {
                    section.contacts.remove(contact)
                    let status = ContactsStatusManager.getStatus(phone: phone)
                    let newSection = status.isOnline ? datasource[1] : sectionsByChar[getFirstChar(contact: contact)]!
                    newSection.contacts.append(contact)
                    phoneSection[phone] = newSection
                    sectionsToSort.insert(newSection)
                }
            }
        }
        
        for section in sectionsToSort {
            section.sortContacts()
        }
    }
    
    func originalCount() -> Int {
        var count = 0
        for section in originalDatasource {
            count += section.contacts.count
        }
        return count
    }
    
    func filterBy(_ searchText: String?) {
        guard let searchTerm = searchText else {
            datasource = originalDatasource
            return
        }
        
        let phoneSearchTerm = Utils.cleanPhone(searchTerm)
        let nameSearchTerm = searchTerm.lowercased()
        var result: [Section] = []
        for section in originalDatasource {
            let newSection = Section(type: section.type)
            newSection.contacts = section.contacts.filter({ contact -> Bool in
                Utils.cleanPhone(contact.phone).contains(phoneSearchTerm) || contact.formatFullName().lowercased().contains(nameSearchTerm)
            })
            result.append(newSection)
        }
        datasource = result
    }
    
    func unreadCounterUpdate(_ missitoContact: RealmMissitoContact) {
        if let _ = phoneContact[missitoContact.phone] {
            phoneContact[missitoContact.phone] = Contact.make(from: missitoContact)
        }
    }
    
    func prepareSections() {
        datasource.removeAll()
        phoneContact.removeAll()
        if isMissitoType {
            let recentlyJoinedSection = Section(type: "RECENTLY_JOINED")
            let onlineSection = Section(type: "ONLINE")
            let blockedSection = Section(type: "BLOCKED")
            datasource.append(recentlyJoinedSection)
            datasource.append(onlineSection)
            
            if let missitoContacts = MissitoRealmDbHelper.getMissitoContacts() {
                for x in missitoContacts {
                    let contact = Contact.make(from: x)
                    phoneContact[contact.phone] = contact
                    
                    let status = ContactsStatusManager.getStatus(phone: contact.phone)
                    if status.isBlocked {
                        blockedSection.contacts.append(contact)
                        phoneSection[contact.phone] = blockedSection
                    } else if contact.isNew() {
                        recentlyJoinedSection.contacts.append(contact)
                        phoneSection[contact.phone] = recentlyJoinedSection
                    } else if status.isOnline {
                        onlineSection.contacts.append(contact)
                        phoneSection[contact.phone] = onlineSection
                    } else {
                        insertToLetterSection(contact)
                    }
                }
            }
            
            appendAllSections()
            datasource.append(blockedSection)
        } else {
            let phoneUtil = NBPhoneNumberUtil.sharedInstance()
            // Check if userID is present and try to extract country code from user phone number
            guard let userID = CoreServices.authService?.userId,
                let userCountryCode = phoneUtil?.extractCountryCode(userID, nationalNumber: nil) else {
                return
            }
            
            for contact in ContactsManager.contacts {
                // Check if contact is already present in user contacts, country code from contact phone number can be extracted, it match with user country code
                guard userID != contact.phone else {
                    continue
                }
                guard !ContactsStatusManager.contains(phone: contact.phone),
                    let contactCountryCode = phoneUtil?.extractCountryCode(contact.phone, nationalNumber: nil),
                    contactCountryCode == userCountryCode else {
                    continue
                }
                
                insertToLetterSection(contact)
                phoneContact[contact.phone] = contact
            }
            appendAllSections()
        }
        
        for section in datasource {
            section.sortContacts()
        }
        
        originalDatasource = datasource
    }
    
    private func insertToLetterSection(_ contact: Contact) {
        let firstChar = getFirstChar(contact: contact)
        
        if sectionsByChar[firstChar] == nil {
            sectionsByChar[firstChar] = Section(type: String(firstChar))
        }
        sectionsByChar[firstChar]!.contacts.append(contact)
        phoneSection[contact.phone] = sectionsByChar[firstChar]!
    }
    
    private func appendAllSections() {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWYZ*"
        
        for ch in alphabet {
            datasource.append(sectionsByChar[ch] ?? Section(type: String(ch)))
        }
    }
    
    func getFirstChar(contact: Contact) -> Character {
        var firstChar = contact.lastName.first ?? contact.firstName.first
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWYZ"
        if firstChar == nil {
            return "*"
        }
        firstChar = Character("\(firstChar!)".uppercased())
        if !alphabet.contains(firstChar!) {
            return "*"
        }
        return firstChar!
    }
}
