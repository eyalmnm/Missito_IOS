//
//  OutgoingAudioChatCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/24/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//
import UIKit

class OutgoingAudioChatCell: OutgoingChatCell {
    
    @IBOutlet weak var audioPlayerView: AudioPlayerView!
    private var phone = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func fill(for message: OutgoingChatMessage, companionPhone: String) {
        phone = companionPhone
        fill(for: message)
    }
    
    override func fill(for message: OutgoingChatMessage) {
        super.fill(for: message)
        audioPlayerView.fill(for: message, contactPhone: phone)
    }
    
    static func getHeight() -> CGFloat {
        return 58
    }
}
