//
//  ContactStatus.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/29/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class ContactStatus {
    
    var isOnline: Bool = false
    var isBlocked: Bool = false
    var isMuted: Bool = false
    var lastSeen: UInt64 = 0
    
    func getStatusLabel() -> String {
        if CoreServices.authService?.reachability?.isReachable ?? false {
            // TODO: localize 'Last seen'
            return isOnline ? "Online" : (lastSeen != 0 ? getLabel() : "")
        }
        
        return ""
    }
    
    private func getLabel() -> String {
        return ("Last seen " + Date.init(timeIntervalSince1970: TimeInterval(lastSeen)).timeAgoSinceNow.lowercased())
    }

}
