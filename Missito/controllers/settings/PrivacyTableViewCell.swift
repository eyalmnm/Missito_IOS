//
//  PrivacyTableViewCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/16/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class PrivacyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var statusSwitch: UISwitch!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var action: (()->())?
    
    @IBAction func switchAction() {
        action?()
    }
}
