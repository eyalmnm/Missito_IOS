//
//  EqualizerView.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/20/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class EqualizerView: UIView {

    @IBOutlet weak var equalizerProgressView: UIProgressView!
    @IBOutlet weak var equalizerView: NVActivityIndicatorView!

    private let MINUTE_IN_MILLISEC = Float(60000)
    var endTime = 0
    var recordDispatchWorkItem: DispatchWorkItem?
    var timerFinishedCallback: (()->())?

    override func awakeFromNib() {
        
    }
    
    func recordingStarted() {
        equalizerProgressView.progress = Float(0)
        equalizerView.startAnimating()
        
        recordDispatchWorkItem?.cancel()
        recordDispatchWorkItem = DispatchWorkItem { [weak self] in
            guard let strongSelf = self,
                !(strongSelf.recordDispatchWorkItem?.isCancelled ?? true) else {
                return
            }
            DispatchQueue.main.sync {
                strongSelf.recordingProgressUpdate()
            }
        }
        endTime = Date().millisecondsSince1970 + Int(MINUTE_IN_MILLISEC)
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.1, execute: recordDispatchWorkItem!)
    }
    
    func recordingStopped() {
        recordDispatchWorkItem?.cancel()
        equalizerView.startAnimating()
    }
    
    func recordingProgressUpdate() {
        let currentTime = Date().millisecondsSince1970
        equalizerProgressView.progress = 1 - Float(endTime - currentTime) / MINUTE_IN_MILLISEC
        if currentTime < endTime {
            if let workItem = recordDispatchWorkItem {
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.1, execute: workItem)
            }
        } else {
            timerFinishedCallback?()
            equalizerView.stopAnimating()
        }
    }
    
    deinit {
        timerFinishedCallback = nil
        recordDispatchWorkItem?.cancel()
    }
}
