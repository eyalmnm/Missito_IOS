//
//  PhoneNumberCell.swift
//  Missito
//
//  Created by George Poenaru on 25/05/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class PhoneNumberCell: UITableViewCell {

    @IBOutlet weak var countryCode: UILabel!
    @IBOutlet weak var phoneNumber: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
