//
//  CustomHeaderCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/2/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class CustomHeaderCell: UITableViewCell {
    @IBOutlet weak var sectionName: UILabel!

    override func awakeFromNib() {
        sectionName.textColor = UIColor.missitoBlue
        sectionName.font = UIFont.SFUIDisplayLight(size: 19.0)
    }
}
