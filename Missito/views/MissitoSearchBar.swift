//
//  MissitoSearchBar.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/2/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome_swift

class MissitoSearchBar: UISearchBar {
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundImage = UIImage.imageWithColor(color: UIColor.missitoLightGrayWithAlpha0x26)
        if let searchTextField = subviews[0].subviews.last as? UITextField {
            searchTextField.layer.cornerRadius = 14
            searchTextField.clipsToBounds = true
            searchTextField.clearButtonMode = .never
            searchTextField.rightViewMode = .always
            searchTextField.leftViewMode = .unlessEditing
        }
    }
}
