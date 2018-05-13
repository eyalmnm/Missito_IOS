//
//  ChatsListCell.swift
//  Missito
//
//  Created by George Poenaru on 16/08/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class ChatsCell: UITableViewCell {

    @IBOutlet weak var chatName: UILabel!
    @IBOutlet weak var lastActivity: UILabel!
    @IBOutlet weak var notificationBubble: NotificationBubble!
    @IBOutlet weak var avatarView: MissitoContactAvatarView!
    @IBOutlet weak var muteBlockIcon: UIImageView!
    @IBOutlet weak var statusView: UIView!
    
    @IBOutlet weak var lastMessage: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.notificationBubble.layer.cornerRadius = self.notificationBubble.frame.height * 0.5
        self.notificationBubble.layer.masksToBounds = true
    }
    
    func fill(for conversation: RealmConversation, lastMessage: NSAttributedString) {
        let contact = conversation.counterparts.first
        let status = ContactsStatusManager.getStatus(phone: contact?.phone ?? "")
        statusView.isHidden = !status.isOnline
        
        let mutedOrBlocked = status.isMuted || status.isBlocked
        muteBlockIcon.isHidden = !mutedOrBlocked
        muteBlockIcon.image = UIImage(named: status.isMuted ? "volume_off" : "ban_icon")
        chatName.text = contact?.formatFullName()
        lastActivity.text = conversation.lastMessage?.timeSent.timeAgoSinceNow ?? ""
        if conversation.unreadCount > 0 && !mutedOrBlocked {
            notificationBubble.counter.text = "\(conversation.unreadCount)"
            notificationBubble.isHidden = false
        } else {
            notificationBubble.isHidden = true
        }
        
        self.lastMessage.attributedText = lastMessage
        avatarView.fill(Contact.make(from: contact!))
    }

}
