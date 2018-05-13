//
//  MissitoContactAvatarView.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/28/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class MissitoContactAvatarView: UIView {

    private static let avatarsNames = [
        "avatar_green",
        "avatar_red",
        "avatar_yellow",
        "avatar_magenta",
        "avatar_blue"
    ]
    
    private var initialsLabel: UILabel?
    private var avatarImageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        let diameter = frame.size.height < frame.size.width ? frame.size.height : frame.size.width;
        let avatarFrame = CGRect(origin: CGPoint(x:0 ,y:0), size: CGSize(width: diameter, height: diameter));
        initialsLabel = UILabel(frame: avatarFrame)
        initialsLabel!.clipsToBounds = true
        initialsLabel!.layer.cornerRadius = diameter/2
        initialsLabel!.font = UIFont.vagrundSchriftDot(size: ceil(diameter*2/3))
        initialsLabel!.textAlignment = NSTextAlignment.center
        initialsLabel!.numberOfLines = 1
        initialsLabel!.backgroundColor = UIColor.clear
        initialsLabel!.textColor = UIColor.white
        avatarImageView = UIImageView(frame: avatarFrame)
        avatarImageView!.clipsToBounds = true
        avatarImageView!.layer.cornerRadius = diameter/2
        addSubview(avatarImageView!)
        addSubview(initialsLabel!)
        initialsLabel!.center.x = diameter/2
        initialsLabel!.center.y = (diameter/2) + 2
        avatarImageView!.layer.borderWidth = 0.5
        avatarImageView!.layer.borderColor = UIColor.missitoGrayCellBackground.cgColor
    }
    
    func fill(_ contact: Contact) {
        if let imageData = contact.imageData {
            initialsLabel!.isHidden = true
            avatarImageView!.image = UIImage.init(data: imageData)
        } else {
            initialsLabel!.isHidden = false
            let position = contact.hashValue % MissitoContactAvatarView.avatarsNames.count
            avatarImageView!.image = UIImage(named:
                MissitoContactAvatarView.avatarsNames[position < 0 ? position * (-1) : position])
            
            initialsLabel!.text = MissitoHelper.getInitials(contact: contact)
        }
    }
}
