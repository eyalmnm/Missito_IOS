//
//  InvitableProtocol.swift
//  Missito
//
//  Created by Mihail Triohin on 2/27/18.
//  Copyright © 2018 Missito GmbH. All rights reserved.
//

import UIKit

protocol Invitable {
    func displayInviteAlertIfNeeded()
}

extension Invitable where Self: UIViewController {
    func displayInviteAlertIfNeeded() {
        let HOURS_48_IN_SECONDS = Double(1440 * 60 * 2)
        
        if NSDate().timeIntervalSince1970 - DefaultsHelper.getLastInvitesNotificationTime() > HOURS_48_IN_SECONDS {
            DefaultsHelper.setLastInvitesNotificationTime()
            
            let inviteView = InviteView(frame: self.view.frame)
            self.view.addSubview(inviteView)
            inviteView.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            
            inviteView.inviteTextLabel.textColor = UIColor.missitoBlue
            inviteView.inviteButton.tintColor = .white
            inviteView.inviteButton.backgroundColor = UIColor.missitoBlue
            inviteView.inviteButton.layer.cornerRadius = 20
            
            inviteView.inviteClosure = { [weak self] in
                let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "InviteContactsTableViewController") as! InviteContactsTableViewController
                self?.navigationController?.pushViewController(controller, animated: true)
                self?.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
        }
    }
}
