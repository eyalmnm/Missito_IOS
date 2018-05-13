//
//  SendInvitesProgressHandler.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/27/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class SendInvitesProgressHandler: ProgressHandler {

    private let selectedPhones: [String]
    
    init(_ selectedPhones: [String]) {
        self.selectedPhones = selectedPhones
        super.init()
        retryAllowed = true
    }
    
    override func start() {
        delegate?.setTitle(title: "Sending invitations")
        APIRequests.sendInvites(lang: Locale.preferredLanguages[0], phones: Array(selectedPhones)) { error in
            if let error = error {
                NSLog("Failed to send invites: %@", error.localizedDescription)
                self.delegate?.stopProgress(withSuccess: false, title: "Could not send invitations. Tap on circle to retry")
            } else {
                self.delegate?.stopProgress(withSuccess: true, title: "Invitations were sent")
            }
        }

    }
}
