//
//  DeleteAudioContainerView.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/20/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class DeleteAudioContainerView: UIView {
    
    @IBOutlet weak var semiTransparentBackground: UIView!
    @IBOutlet weak var deleteIcon: UIImageView!
    
    var whiteTrashCan, redTrashCan: UIImage?
    
    override func awakeFromNib() {
        whiteTrashCan = UIImage.fontAwesomeIcon(name: .trashO, textColor: UIColor.white, size: CGSize.init(width: 50, height: 50))
        redTrashCan = UIImage.fontAwesomeIcon(name: .trashO, textColor: UIColor.red, size: CGSize.init(width: 50, height: 50))
        deleteIcon.image = whiteTrashCan
    }
    
    func updateIcon(_ active: Bool) {
        if active {
            deleteIcon.image = redTrashCan
        } else {
            deleteIcon.image = whiteTrashCan
        }
    }
}
