//
//  CustomControllerTitleView.swift
//  Missito
//
//  Created by Jenea Vranceanu on 12/11/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class CustomTitleView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        frame.size.width = CGFloat.greatestFiniteMagnitude
    }
    
    override var intrinsicContentSize: CGSize {
        return UILayoutFittingExpandedSize
    }
}
