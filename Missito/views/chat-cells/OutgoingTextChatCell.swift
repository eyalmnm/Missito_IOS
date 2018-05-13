//
//  OutgoingTextChatCell.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class OutgoingTextChatCell: OutgoingChatCell {

    @IBOutlet weak var messageTextLabel: UILabel!
    
    private var onTap: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageTextLabel.font = BaseChatCell.defaultLabelFont
        bubble.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMessageTap)))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func onMessageTap() {
        onTap?()
    }
    
    func fill(for message: OutgoingChatMessage, onTap: @escaping () -> ()) {
        super.fill(for: message)
        messageTextLabel.text = message.text
        self.onTap = onTap
    }
    
    static func getHeight(_ message: OutgoingChatMessage) -> CGFloat {
        let totalTopBottomConstraints: CGFloat = 28
        let totalLeftRightConstraints: CGFloat = 174
        let maxBubbleWidth: CGFloat = UIScreen.main.bounds.width - totalLeftRightConstraints
        return totalTopBottomConstraints + (message.text ?? "").height(maxWidth: maxBubbleWidth, font: BaseChatCell.defaultLabelFont)
    }
}
