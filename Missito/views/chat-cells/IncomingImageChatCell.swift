//
//  IncomingImageChatCell.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class IncomingImageChatCell: IncomingChatCell {

    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    private var forwardClosure: (()->())?
    private var openFullScreenClosure: (()->())?
    private var onMoreMenuClosure: ((URL)->())?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imgView.layer.borderColor = UIColor.missitoGrayCellBackground.cgColor
        imgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onImageClicked(sender:))))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func onForward(_ sender: Any) {
        forwardClosure?()
    }
    
    func onImageClicked(sender: Any) {
        openFullScreenClosure?()
    }
    
    @IBAction func onMore(_ sender: UIButton) {
        onMoreMenuClosure?(fileURL)
    }
    
    func fill(for message: IncomingChatMessage, fullScreenAction: @escaping (()->()), onForward: @escaping (()->()), onMoreMenu: @escaping ((URL)->())) {
        super.fill(for: message)
        bubble.backgroundColor = UIColor.clear
        
        if let attach = message.attachment {
            let image = attach.images[0]
            let img = UIImage.fromBase64(image.thumbnail)
            
            // TODO: what if image is missing (broken base64 data or something)
            let scale = UIScreen.main.scale
            
            let maxWidth = (UIScreen.main.bounds.width - leadingConstraint.constant - trailingConstraint.constant) * scale
            let maxHeight = 400 * scale
            
            UIHelper.setImageWithConstraints(imageView: imgView, image: img,
                                             widthConstraint: widthConstraint, heightConstraint: heightConstraint,
                                             maxWidth: maxWidth, maxHeight: maxHeight)
            
            forwardClosure = onForward
            openFullScreenClosure = fullScreenAction
            onMoreMenuClosure = onMoreMenu
            setupMoreButton(message: message)
        }
    }
    
    private func setupMoreButton(message: IncomingChatMessage) {
        guard
            let url = Utils.getFileURL(phone: message.senderContact.phone, fileName: message.attachment!.images.first!.fileName),
            FileManager.default.fileExists(atPath: url.path, isDirectory: nil)
            else {
                moreButton.isHidden = true
                return
        }
        
        fileURL = url
        moreButton.isHidden = false
    }
    
    static func getHeight(_ message: IncomingChatMessage) -> CGFloat {
        if let images = message.attachment?.images {
            let totalTopBottomConstraints: CGFloat = 4
            let totalLeftRightOuterConstraints: CGFloat = 154
            let image = images[0]
            let img = UIImage.fromBase64(image.thumbnail)
            
            // TODO: what if image is missing (broken base64 data or something)
            let scale = UIScreen.main.scale
            
            let maxWidth = (UIScreen.main.bounds.width - totalLeftRightOuterConstraints) * scale
            let maxHeight = 400 * scale
            
            return UIHelper.calcImageSize(image: img, maxWidth: maxWidth, maxHeight: maxHeight).height + totalTopBottomConstraints
        }
        
        return 104 // 100 img default height + 4 (2 from top and 2 from bottom offset) 
    }
    
}
