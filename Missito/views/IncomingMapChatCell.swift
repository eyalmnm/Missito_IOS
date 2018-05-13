//
//  IncomingMapChatCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/23/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class IncomingMapChatCell: IncomingTextChatCell {

    @IBOutlet weak var mapImageView: UIImageView!
    
    private var onClickClosure: (()->())?
    private var forwardClosure: (()->())?
    private var onMoreMenuClosure: ((URL)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        bubble.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(onBubbleTap(sender:))))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func onBubbleTap(sender: UIView) {
        onClickClosure?()
    }
    
    @IBAction func onForward(_ sender: Any) {
        forwardClosure?()
    }
    
    @IBAction func onMore(_ sender: UIButton) {
        onMoreMenuClosure?(fileURL)
    }
    
    func fill(message: IncomingChatMessage, onClick: @escaping (()->()) , createSnapshot: @escaping (RealmLocation, CGSize)->(UIImage?), onForward: @escaping ()->(), onMoreMenu: @escaping ((URL)->())) {
        super.fill(for: message)
        if let locations = message.attachment?.locations, !locations.isEmpty {
            let realmLocation = locations[0]
            mapImageView.image = createSnapshot(realmLocation, mapImageView.frame.size)
            // For message of Geo type 'message' text is ignored and location label is shown instead
            messageTextLabel.text = realmLocation.label
        } else {
            mapImageView.image = ChatController.mapPlaceholderUIImage
            messageTextLabel.text = nil
        }
        onClickClosure = onClick
        forwardClosure = onForward
        setupMoreButton(message: message)
        onMoreMenuClosure = onMoreMenu
    }
    
    private func setupMoreButton(message: IncomingChatMessage) {
        guard
            case let l = message.attachment!.locations.first!,
            let url = URL(string: "http://maps.apple.com/?ll=\(l.lat),\(l.lon)&q=\(l.lat),\(l.lon)&t=m")
            else {
                moreButton.isHidden = true
                return
        }
        
        fileURL = url
        moreButton.isHidden = false
    }
    
    static func getMapCellHeight(_ message: IncomingChatMessage) -> CGFloat {
        let totalTopBottomConstarints: CGFloat = 24
        let fixedMapHeight: CGFloat = 110
        
        let maxTextLabelWidth: CGFloat = 164 // fixed map width - constraints - date label width - status img width
        
        var text = ""
        if let locations = message.attachment?.locations, !locations.isEmpty {
            let realmLocation = locations[0]
            text = realmLocation.label
            
            return fixedMapHeight + totalTopBottomConstarints + text.height(maxWidth: maxTextLabelWidth, font: BaseChatCell.defaultLabelFont)
        }
        
        return 150 // 146 cell default height + 4 (2 from top and 2 from bottom offset)
    }
    
}
