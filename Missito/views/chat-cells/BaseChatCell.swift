//
//  BaseChatCell.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos
import MBProgressHUD

class BaseChatCell: UITableViewCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var bubble: UIView!
    /// Should be present only on image, video and location messages
    @IBOutlet weak var moreButton: UIButton!

    static let defaultLabelFont = UIFont.SFUIDisplayLight(size: 13.0)
    /// For image, and video it is local path to attachment, for location it is apple maps scheme url
    var fileURL: URL!
    
    var message: ChatMessage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization
        timeLabel.font = UIFont.SFUIDisplayLight(size: 10.0)
        selectionStyle = .none
        bubble.layer.cornerRadius = 3
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func fill(for message: ChatMessage) {
        self.message = message
        bubble.backgroundColor = (message.direction == .incoming ? UIColor.missitoGrayCellBackground : UIColor.missitoBlue)
        timeLabel.text = message.date.format(with: "HH:mm")
        
        let corners = getCornersToRound(message.direction, message.inGroupType)
        
        if let bubbleView = (bubble as? BubbleView) {
            bubbleView.setup(corners)
        } else if let bubbleImageView = (bubble as? BubbleImageView) {
            bubbleImageView.setup(corners)
        }
        NSLog("fill \(message.text ?? "") - \(message.inGroupType)")
        
    }
    
    private func getCornersToRound(_ direction: BaseChatMessage.Direction, _ inGroupType: BaseChatMessage.MessageInGroupType)->UIRectCorner {
        var corners = UIRectCorner.allCorners
        if direction == .outgoing {
            switch inGroupType {
            case .first:
                corners.remove(UIRectCorner.bottomRight)
            case .middle:
                corners.remove(UIRectCorner.topRight)
                corners.remove(UIRectCorner.bottomRight)
            case .last:
                corners.remove(UIRectCorner.topRight)
            default: break
            }
        } else {
            switch inGroupType {
            case .first:
                corners.remove(UIRectCorner.bottomLeft)
            case .middle:
                corners.remove(UIRectCorner.topLeft)
                corners.remove(UIRectCorner.bottomLeft)
            case .last:
                corners.remove(UIRectCorner.topLeft)
            default: break
            }
        }
        return corners
    }
}
