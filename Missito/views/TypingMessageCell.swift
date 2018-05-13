//
//  TypingMessageCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class TypingMessageCell: UITableViewCell {
    
    @IBOutlet weak var typingLabel: UILabel!
    
    func prepare(_ contact: Contact?) {
        var name = ""
        if let contactName = contact?.formatFullName(), !contactName.isEmpty {
            name = contactName
        } else {
            name = (contact?.phone ?? "")
        }
        
        typingLabel.text = name + " is typing ..."
    }
}
