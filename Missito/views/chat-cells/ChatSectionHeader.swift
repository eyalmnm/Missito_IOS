//
//  ChatSectionHeader.swift
//  Missito
//
//  Created by Alex Gridnev on 8/28/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class ChatSectionHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.textColor = UIColor.missitoLightGray
        headerLabel.font = UIFont.SFUIDisplayLight(size: 13)
    } 
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
