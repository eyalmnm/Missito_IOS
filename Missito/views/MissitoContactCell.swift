//
//  MissitoContactCell.swift
//  Missito
//
//  Created by George Poenaru on 12/08/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class MissitoContactCell: UITableViewCell {

    @IBOutlet weak var avatarView: MissitoContactAvatarView!
    @IBOutlet weak var blockedStateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var lastSeenLabel: UILabel!
    @IBOutlet weak var muteBlockIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateFor(contact: Contact) {
        let contactStatus = ContactsStatusManager.getStatus(phone: contact.phone)
        
        muteBlockIcon.isHidden = !contactStatus.isMuted && !contactStatus.isBlocked
        muteBlockIcon.image = UIImage(named: contactStatus.isBlocked ? "ban_icon" : "volume_off")
        if contactStatus.isBlocked  {
            blockedStateLabel.isHidden = true
        } else {
            blockedStateLabel.textColor = UIColor.greenM
            blockedStateLabel.text = contact.isNew() ? "NEW" : ""
            blockedStateLabel.isHidden = contactStatus.isMuted || !contact.isNew()
        }
        
        nameLabel.text = contact.formatFullName()
        avatarView.fill(contact)
        
        lastSeenLabel.text = getLastSeenLabel(contactStatus)
        lastSeenLabel.textColor = contactStatus.isBlocked ? UIColor.missitoLightGray : contactStatus.isOnline ? UIColor.greenM : UIColor.missitoLightGray

//        cell.unreadCount.isHidden = contact.unreadCount == 0
//        cell.unreadCount.text = (contact.unreadCount > 99 ? "99+" : String(contact.unreadCount))

        phoneLabel.text = contact.phone
        
        // Set the contact image.
        /*if let imageData = contact.imageData {
         aCell.profileImageView.image = UIImage(data: imageData)
         }*/
    }
    
    func getLastSeenLabel(_ status: ContactStatus) -> String {
        if status.isOnline {
            return "Online"
        }
        if status.lastSeen == 0 {
            return ""
        }
        return Date.init(timeIntervalSince1970: TimeInterval(status.lastSeen)).timeAgoSinceNow
    }

}
