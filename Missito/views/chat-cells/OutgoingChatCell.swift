//
//  OutgoingChatCell.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class OutgoingChatCell: BaseChatCell {
    
    @IBOutlet weak var statusImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        statusImageView.tintColor = UIColor.white
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fill(for message: OutgoingChatMessage) {
        super.fill(for: message)
        
        let status = message.status
        statusImageView.image = UIImage(named: (status == .delivered
            ? "chat_sent"
            : (status == .seen
                ? "chat_received"
                : "")))
    }

}
