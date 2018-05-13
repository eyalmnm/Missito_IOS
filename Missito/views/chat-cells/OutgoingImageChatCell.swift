//
//  OutgoingImageChatCell.swift
//  Missito
//
//  Created by Alex Gridnev on 8/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class OutgoingImageChatCell: OutgoingChatCell, ProgressUpdatable {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var statusImageWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var statusImageTrailingConstraint: NSLayoutConstraint!
    
    private var forwardClosure: (()->())?
    private var openFullScreenClosure: (()->())?
    private var onMoreMenuClosure: ((URL)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onImageClicked(sender:))))
        imgView.layer.borderColor = UIColor.missitoGrayCellBackground.cgColor
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
    
    func fill(for message: OutgoingChatMessage, fullScreenAction: @escaping (()->()), onForward: @escaping (()->()), onMoreMenu: @escaping ((URL)->())) {
        super.fill(for: message)
        bubble.backgroundColor = UIColor.clear
        
        if statusImageView.image != nil {
            statusImageWidthConstraint.constant = 15
            statusImageTrailingConstraint.constant = 6
        } else {
            statusImageWidthConstraint.constant = 0
            statusImageTrailingConstraint.constant = 3
        }
        
        if let attach = message.attachment {
            let image = attach.images[0]
            let img = UIImage.fromBase64(image.thumbnail)
            // TODO: what if image is missing (broken base64 data or something)
            let scale = UIScreen.main.scale
            
            let maxWidth = (UIScreen.main.bounds.width - leadingConstraint.constant - trailingConstraint.constant) * scale
            let maxHeight = 400 * scale
            
//            NSLog("WIDTH %f %f %f", UIScreen.main.bounds.width, leadingConstraint.constant, trailingConstraint.constant)
            
            UIHelper.setImageWithConstraints(imageView: imgView, image: img,
                                             widthConstraint: widthConstraint, heightConstraint: heightConstraint,
                                             maxWidth: maxWidth, maxHeight: maxHeight)
            
            updateFor(progress: message.progress)
            setupMoreButton(message: message)
            forwardClosure = onForward
            openFullScreenClosure = fullScreenAction
            onMoreMenuClosure = onMoreMenu
        }
    }
    
    private func setupMoreButton(message: OutgoingChatMessage) {
        guard
            let url = Utils.getFileURL(phone: message.destContact!.phone, fileName: message.attachment!.images.first!.fileName),
            FileManager.default.fileExists(atPath: url.path, isDirectory: nil)
        else {
            moreButton.isHidden = true
            return
        }
        
        fileURL = url
        moreButton.isHidden = false
    }
    
    func updateFor(progress: Float?) {
        if let progress = progress, progress < 1 {
            progressView.progress = progress
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }
    }
    
    static func getHeight(_ message: OutgoingChatMessage) -> CGFloat {
        if let images = message.attachment?.images {
            let totalTopBottomConstraints: CGFloat = 4
            let totalLeftRightOuterConstraints: CGFloat = 150
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
