//
//  ProgressViewController.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/27/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit
import M13ProgressSuite

class ProgressViewController: UIViewController, ProgressDelegate {

    var progressHandler: ProgressHandler?
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var progressView: M13ProgressViewRing!
    @IBOutlet weak var cancelButton: UIButton!
    
    private var inProgress = false
    private var isSuccess = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action:  #selector (self.onProgressTap(_:)))
        progressView.addGestureRecognizer(tapRecognizer)
        progressView.showPercentage = false
        progressView.progressRingWidth = 4
        
        progressHandler?.delegate = self
        inProgress = true
        progressHandler?.start()
    }
    
    func onProgressTap(_ sender:UITapGestureRecognizer) {
        if !inProgress {
            if !isSuccess && (progressHandler?.retryAllowed ?? false) {
                inProgress = true
                cancelButton.isHidden = true
                progressView.indeterminate = true
                progressView.setProgress(0.5, animated: true)
                progressHandler?.start()
            } else {
                finish()
            }
        }
    }
    
    private func finish() {
        _ = navigationController?.popToRootViewController(animated: false)
        (UIApplication.shared.keyWindow?.rootViewController as! UITabBarController).selectedIndex = 0
    }
    
    func stopProgress(withSuccess success: Bool, title: String?) {
        if (progressHandler?.retryAllowed ?? false) && !success {
            cancelButton.isHidden = false
        }
        topLabel.text = title
        inProgress = false
        isSuccess = success
        progressView.indeterminate = false
        progressView.setProgress(1, animated: true)
        progressView.primaryColor = success ? UIColor.green : UIColor.red
        progressView.secondaryColor = success ? UIColor.green : UIColor.red
        progressView.perform(success ? M13ProgressViewActionSuccess : M13ProgressViewActionFailure, animated: true)
    }
    
    func setTitle(title: String) {
        topLabel.text = title
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        if !inProgress {
            finish()
        }
    }
}
