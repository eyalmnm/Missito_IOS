//
//  AllContactCell.swift
//  Missito
//
//  Created by George Poenaru on 12/08/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class AllContactCell: UITableViewCell {


    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var firstName: UILabel!
    
    @IBOutlet weak var secondName: UILabel!
    
    @IBOutlet weak var isContactSelected: UISwitch!
    
    @IBOutlet weak var phone: UILabel!
    
    @IBOutlet weak var placeholder: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height * 0.5
        self.profileImageView.layer.masksToBounds = true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
