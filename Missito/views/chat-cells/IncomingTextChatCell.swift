//
//  IncomingTextChatCell.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class IncomingTextChatCell: IncomingChatCell {

    @IBOutlet weak var messageTextLabel: UILabel!
    
    private var onTap: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageTextLabel.font = UIFont.SFUIDisplayLight(size: 13.0)
        bubble.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMessageTap)))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func onMessageTap() {
        onTap?()
    }
    
    func fill(for message: IncomingChatMessage, onTap: @escaping () -> ()) {
        super.fill(for: message)
        messageTextLabel.text = message.text
        self.onTap = onTap
    }

    static func getHeight(_ message: IncomingChatMessage) -> CGFloat {
        let totalTopBottomConstraints: CGFloat = 24
        let totalLeftRightConstraints: CGFloat = 172
        let maxBubbleWidth: CGFloat = UIScreen.main.bounds.width - totalLeftRightConstraints
        return totalTopBottomConstraints + (message.text ?? "").height(maxWidth: maxBubbleWidth, font: BaseChatCell.defaultLabelFont) + 4
    }
    
}
