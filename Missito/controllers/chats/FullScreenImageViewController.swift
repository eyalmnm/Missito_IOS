//
//  FullScreenImageViewController.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/7/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

class FullScreenImageViewController: UIViewController, UIScrollViewDelegate {

    var message: ChatMessage?
    var phone: String?
    let gradientLayer = CAGradientLayer()

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var sendButton: UILabel!
    @IBOutlet weak var cancelButton: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var progress: MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isStatusBarHidden = true
        
        cancelButton.isUserInteractionEnabled = true
        cancelButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCanceled(recognizer:))))
        
        sendButton.isHidden = true
        cancelButton.text = "Close"

//        sendButton.isUserInteractionEnabled = true
//        sendButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onSendTapped(recognizer:))))
        
        // Top gradient
        gradientLayer.frame = headerView.bounds
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        headerView.layer.addSublayer(gradientLayer)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(FullScreenImageViewController.onDownload(notification:)),
                                               name: DownloadService.DOWNLOAD_FINISH_NOTIF, object: nil)
        displayImage()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func displayImage() {
        
        guard let attach = message?.attachment, !attach.images.isEmpty else {
            NSLog("Can't open image: no attachment")
            return
        }
        let realmImage = attach.images[0]
        
        guard let fileURL = Utils.getFileURL(phone: phone, fileName: realmImage.fileName) else {
            return
        }
        
        if !FileManager.default.fileExists(atPath: fileURL.path, isDirectory: nil) {
            progress = Utils.showProgress(message: "Loading...", view: self.view)
            CoreServices.downloadService?.downloadImageFile(senderPhone: phone!, message: message!)
        } else if let image = UIImage(contentsOfFile: fileURL.path) {
            imageView.image = image
            progress?.hide(animated: true)
        } else {
            progress?.hide(animated: true)
            dismiss(animated: true)
            NSLog("Failed to show image: couldn't create UIImage from contents of file %@", fileURL.path)
            return
        }
    }
    
    func onDownload(notification: Notification) {
        if let userInfo = notification.userInfo {
            //            let fileUrl = userInfo[DownloadService.URL_KEY] as? String
            let error = userInfo[DownloadService.ERROR_KEY] as? Error
            let messageId = userInfo[DownloadService.MESSAGE_ID_KEY] as? String
            
            guard let id1 = messageId, let id2 = message?.id, id1 == id2 else {
                return
            }
            
            if let _ = error {
                progress?.hide(animated: true)
                dismiss(animated: true)
            } else {
                displayImage()
            }
        }
    }
    
    func onCanceled(recognizer: UITapGestureRecognizer) {
        UIApplication.shared.isStatusBarHidden = false
        dismiss(animated: true)
    }
    
//    func onSendTapped(recognizer: UITapGestureRecognizer) {
//        send()
//    }
//
//    func send() {
//        if let sendClosure = onSend {
//            dismiss(animated: true)
//            sendClosure(nil)
//        }
//    }
    
}
