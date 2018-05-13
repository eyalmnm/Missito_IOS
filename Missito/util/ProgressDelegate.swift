//
//  ProgressDelegate.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/27/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

protocol ProgressDelegate {
    func stopProgress(withSuccess success: Bool, title: String?)
    func setTitle(title: String)
}

class ProgressHandler {
    var retryAllowed = false
    var delegate: ProgressDelegate?
    
    func start() {
        fatalError("This method must be overridden")
    }
}
