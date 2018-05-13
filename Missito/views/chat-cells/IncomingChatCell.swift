//
//  IncomingChatCell.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class IncomingChatCell: BaseChatCell {

    @IBOutlet weak var avatarView: MissitoContactAvatarView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fill(for message: IncomingChatMessage) {
        super.fill(for: message)
        if message.inGroupType == .single || message.inGroupType == .last {
            avatarView.fill(message.senderContact)
            avatarView.isHidden = false
        } else {
            avatarView.isHidden = true
        }
    }

}
