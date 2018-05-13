//
//  IncomingVideoChatCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 9/22/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit
import AVFoundation
import NVActivityIndicatorView

class IncomingVideoChatCell: IncomingChatCell {
    
    @IBOutlet weak var loadingIndicatorView: NVActivityIndicatorView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    private var forwardClosure: (()->())?
    private var playVideoInFullScreenAction: (()->())?
    private var onMoreMenuClosure: ((URL)->())?
    private var filePath: String?
    private var fileName: String?
    private var phone = ""
    
    private static let playTitle = " " + String.fontAwesomeIcon(name: .play)

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        playButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20)
        playButton.layer.borderColor = UIColor.white.cgColor
        imgView.layer.borderColor = UIColor.missitoGrayCellBackground.cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    private func setupNotDownloadedState(message: IncomingChatMessage) {
        if message.progress != nil {
            loadingIndicatorView.startAnimating()
            playButton.setTitle(nil, for: .normal)
            playButton.setImage(nil, for: .normal)
        } else {
            playButton.setImage(#imageLiteral(resourceName: "ic_download"), for: .normal)
            playButton.setTitle(nil, for: .normal)
        }
    }

    private func setupDownloadedState() {
        playButton.setImage(nil, for: .normal)
        playButton.setTitle(IncomingVideoChatCell.playTitle, for: .normal)
    }
    
    private func fileIsAvailable() -> Bool {
        // TODO: we should store relative paths to avoid this
        if let path = filePath, let url = URL(string: path), AVAsset(url: url).isPlayable {
            return true
        } else if let fileName = fileName,
            let fileURL = Utils.getFileURL(phone: phone, fileName: fileName),
            AVAsset(url: fileURL).isPlayable {
            return true
        }
        return false
    }

    @IBAction func onPlayClicked(_ sender: Any) {
        if let closure = playVideoInFullScreenAction {
            if !fileIsAvailable() {
                loadingIndicatorView.startAnimating()
                playButton.setTitle(nil, for: .normal)
                playButton.setImage(nil, for: .normal)
            }
            
            closure()
        }
    }
    
    @IBAction func onForward(_ sender: Any) {
        forwardClosure?()
    }
    
    @IBAction func onMore(_ sender: UIButton) {
        onMoreMenuClosure?(fileURL)
    }
    
    func fill(for message: IncomingChatMessage, playAction: @escaping (()->()), onForward: @escaping (()->()), onMoreMenu: @escaping ((URL)->())) {
        super.fill(for: message)
        bubble.backgroundColor = UIColor.clear
        
        if let attach = message.attachment {
            let video = attach.video[0]
            let img = UIImage.fromBase64(video.thumbnail)
            
            phone = message.senderContact.phone
            filePath = video.localPath
            fileName = video.fileName
            
            // TODO: what if image is missing (broken base64 data or something)
            let scale = UIScreen.main.scale
            
            let maxWidth = (UIScreen.main.bounds.width - leadingConstraint.constant - trailingConstraint.constant) * scale
            let maxHeight = 400 * scale
            
            UIHelper.setImageWithConstraints(imageView: imgView, image: img,
                                             widthConstraint: widthConstraint, heightConstraint: heightConstraint,
                                             maxWidth: maxWidth, maxHeight: maxHeight)
            
            forwardClosure = onForward
            playVideoInFullScreenAction = playAction
            setupMoreButton(message: message)
            onMoreMenuClosure = onMoreMenu
            
            if fileIsAvailable() {
                setupDownloadedState()
                loadingIndicatorView.stopAnimating()
            } else {
                setupNotDownloadedState(message: message)
            }
        }
    }
    
    private func setupMoreButton(message: IncomingChatMessage) {
        guard
            let url = Utils.getFileURL(phone: message.senderContact.phone, fileName: message.attachment!.video.first!.fileName),
            AVAsset(url: url).isPlayable
            else {
                moreButton.isHidden = true
                return
        }
        
        fileURL = url
        moreButton.isHidden = false
    }
    
    static func getHeight(_ message: IncomingChatMessage) -> CGFloat {
        if let videos = message.attachment?.video {
            let totalTopBottomConstraints: CGFloat = 4
            let totalLeftRightOuterConstraints: CGFloat = 154
            let video = videos[0]
            let img = UIImage.fromBase64(video.thumbnail)
            
            // TODO: what if image is missing (broken base64 data or something)
            let scale = UIScreen.main.scale
            
            let maxWidth = (UIScreen.main.bounds.width - totalLeftRightOuterConstraints) * scale
            let maxHeight = 400 * scale
            
            return UIHelper.calcImageSize(image: img, maxWidth: maxWidth, maxHeight: maxHeight).height + totalTopBottomConstraints
        }
        
        return 104 // 100 img default height + 4 (2 from top and 2 from bottom offset)
    }
    
}
