//
//  IncomingContactChatCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/23/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class IncomingContactChatCell: IncomingChatCell {
    
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactPhonesAndEmailsLabel: UILabel!
    @IBOutlet weak var contactImage: UIImageView!
    
    private var onClickAction: (()->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contactImage.layer.borderWidth = CGFloat(0.5)
        contactImage.layer.borderColor = UIColor.missitoBlue.cgColor
        contactNameLabel.font = UIFont.SFUIDisplayLight(size: 13.0)
        contactPhonesAndEmailsLabel.font = UIFont.SFUIDisplayLight(size: 13.0)
        bubble.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onContactClicked(sender:))))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func onContactClicked(sender: Any) {
        onClickAction?()
    }
    
    func fill(for message: IncomingChatMessage, onClickAction: (()->())?) {
        super.fill(for: message)
        if let contacts = message.attachment?.contacts, let contact = contacts.first {
            self.onClickAction = onClickAction
            if let bytes = contact.avatar {
                contactImage.image = UIImage.fromBase64(bytes)
            } else {
                contactImage.image = UIImage(named: "avatar_placeholder")
            }
            contactNameLabel.text = contact.formatFullName()
            
            contactPhonesAndEmailsLabel.text = IncomingContactChatCell.getPhonesAndEmailsStr(for: contact)
        } else {
            contactImage.image = UIImage(named: "avatar_placeholder")
            contactNameLabel.text = nil
            contactPhonesAndEmailsLabel.text = nil
        }
    }
    
    static func getPhonesAndEmailsStr(for contact: RealmAttachmentContact) -> String {
        let phones = Utils.getPhones(contact, joinedWith: ", ")
        let emails = Utils.getEmails(contact, joinedWith: ", ")
        return !phones.isEmpty ? phones + "\n" + emails : emails
    }
    
    func setTapGesture(_ indexPath: IndexPath, _ gesture: UITapGestureRecognizer) {
        let container = contactNameLabel.superview!
        container.tag = indexPath.row
        container.gestureRecognizers?.removeAll()
        container.addGestureRecognizer(gesture)
    }
    
    static func getHeight(_ message: IncomingChatMessage) -> CGFloat {
        let totalTopBottomConstraints: CGFloat = 48
        let totalLeftRightConstraints: CGFloat = 186
        let maxTextLabelWidth: CGFloat = UIScreen.main.bounds.width - totalLeftRightConstraints
        
        var emailsAndPhonesLabelHeight: CGFloat = 0
        var contactNameLabelHeight: CGFloat = 0
        if let contacts = message.attachment?.contacts, let contact = contacts.first {
            
            let name = contact.formatFullName()
            if !name.isEmpty {
                contactNameLabelHeight = contact.formatFullName().height(maxWidth: maxTextLabelWidth, font: BaseChatCell.defaultLabelFont)
                contactNameLabelHeight = contactNameLabelHeight > 32 ? 32 : contactNameLabelHeight
            }
            
            emailsAndPhonesLabelHeight = IncomingContactChatCell.getPhonesAndEmailsStr(for: contact).height(maxWidth: maxTextLabelWidth, font: BaseChatCell.defaultLabelFont)
            
            return totalTopBottomConstraints
                + contactNameLabelHeight
                + (emailsAndPhonesLabelHeight > 0 ? emailsAndPhonesLabelHeight : 14)
        }
        
        return 74 // 70 cell default height + 4 (2 from top and 2 from bottom offset)
    }
    
}
