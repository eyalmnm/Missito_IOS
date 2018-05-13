//
//  UserInfoView.swift
//  Missito
//
//  Created by Alex Gridnev on 8/9/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class UserInfoView: UIView {


    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!

    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBAction func onInfoClick(_ sender: Any) {
        NSLog("UserInfoView info click")
    }

}
