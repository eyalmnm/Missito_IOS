//
//  MissitoHelper.swift
//  Missito
//
//  Created by Alex Gridnev on 8/17/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class MissitoHelper {
    
    static func getInitials(contact: Contact) -> String {
        if let secondNameInitial = contact.lastName.characters.first {
            return String(secondNameInitial).uppercased()
        }
        if let firstNameInitial = contact.firstName.characters.first {
            return String(firstNameInitial).uppercased()
        }
        return ""
    }
    
    // Check if UUID from Defaults is not nil and equal with UUID from KeyChain
    static func wasAppReinstalled() -> Bool {
        return !(DefaultsHelper.getInstallId() != nil && KeyChainHelper.getInstallId() != nil && DefaultsHelper.getInstallId() == KeyChainHelper.getInstallId())
    }
}
