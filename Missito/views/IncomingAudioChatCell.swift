//
//  IncomingAudioChatCell.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/24/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class IncomingAudioChatCell: IncomingChatCell {
    
    @IBOutlet weak var audioPlayerView: AudioPlayerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func fill(for message: IncomingChatMessage) {
        super.fill(for: message)
        audioPlayerView.fill(for: message, contactPhone: message.senderContact.phone) { [weak self] in
            guard let _ = self else {
                return
            }
            CoreServices.downloadService?.downloadAudioFile(senderPhone: message.senderContact.phone, message: message)
        }
    }
    
    static func getHeight() -> CGFloat {
        return 58
    }
}
