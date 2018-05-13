//
//  SeparatorlessTableViewCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 9/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class SeparatorlessTableViewCell: UITableViewCell {
    
    override func addSubview(_ view: UIView) {
        // The separator has a height of 0.5pt on a retina display and 1pt on non-retina.
        // Prevent subviews with this height from being added.
        if view.frame.height * UIScreen.main.scale == 1 {
            return
        }
            
        super.addSubview(view)
    }
}
