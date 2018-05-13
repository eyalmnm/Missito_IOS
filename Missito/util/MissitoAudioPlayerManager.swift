//
//  MissitoAudioPlayerManager.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/25/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

class MissitoAudioPlayerManager: NSObject, AVAudioPlayerDelegate {

    static let ON_STOP_PLAYING_RECORD = Notification.Name("on_stop_playing_record")
    static let RECORD_URL_KEY = "played_record_url_key"
    
    private static let shared = MissitoAudioPlayerManager()
    public private(set) static var player: AVAudioPlayer?
    
    static func playing(_ url: URL?)->Bool {
        guard let player = MissitoAudioPlayerManager.player else { return false }
        return player.url != nil && url != nil && player.url! == url!
    }
    
    static func prepareToPlay(_ url: URL?) -> Bool {
        MissitoAudioPlayerManager.stop()
        guard let url = url,
            let player = try? AVAudioPlayer(contentsOf: url) else {
                return false
        }
        
        player.volume = 1
        player.delegate = shared
        player.numberOfLoops = 0
        MissitoAudioPlayerManager.player = player
        return true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        MissitoAudioPlayerManager.stop()
    }
    
    static func play() {
        guard let player = MissitoAudioPlayerManager.player else {
            NSLog("Failed to start AVAudioPlayer because player is nil!")
            return
        }
        player.play()
    }
    
    static func stop() {
        if let player = MissitoAudioPlayerManager.player  {
            NotificationCenter.default.post(
                Notification(name: MissitoAudioPlayerManager.ON_STOP_PLAYING_RECORD,
                             object: nil,
                             userInfo: [MissitoAudioPlayerManager.RECORD_URL_KEY : player.url!])
            )
            player.stop()
        }
    }
}
