//
//  MissitoAudioRecorder.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/20/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class MissitoAudioRecorder {

    static let shared = MissitoAudioRecorder()
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var isRecorderPaused = false
    var realmAudio: RealmAudio?
    
    init?() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [AVAudioSessionCategoryOptions.defaultToSpeaker, .mixWithOthers])
            try recordingSession.setActive(true)
        } catch let error {
            NSLog("Failed to record: %@", error.localizedDescription)
            return nil
        }
    }
    
    deinit {
        try? recordingSession.setActive(false)
    }
    
    func hasPermission() -> Bool {
        return recordingSession.recordPermission() == .granted
    }
    
    func requestRecordPermission(with viewController: UIViewController) {
        recordingSession.requestRecordPermission() { allowed in
            if allowed {
                NSLog("Permission granted for recording audio")
            } else {
                Utils.alert(viewController: viewController, title: "Cannot record audio messages", message: "You have to grant permission to use audio record tools")
                NSLog("Failed to record: no permission to record")
            }
        }
    }
    
    func startRecording(_ contactPhone: String?) {
        isRecorderPaused = false
        let prefix = Date.init(timeIntervalSince1970: NSDate().timeIntervalSince1970).format(with: "ddMMMYY_hhmmssa")
        if let audioFileURL = Utils.getFileURL(phone: contactPhone, fileName: prefix + ".m4a") {
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
                audioRecorder.record()
                realmAudio = RealmAudio()
                realmAudio?.fileName = audioFileURL.lastPathComponent
                realmAudio?.title = audioFileURL.lastPathComponent
                realmAudio?.secret = EncryptionHelper.generateRandomAES256Key()
            } catch let exception {
                finishRecording(success: false)
                NSLog("Failed to start audio recorder: %@", exception.localizedDescription)
            }
        }
    }
    
    func finishRecording(success: Bool, _ completion: ((RealmAudio)->())? = nil) {
        guard let audioRecorder = audioRecorder else {
            return
        }
        
        audioRecorder.stop()
        
        if let realmAudio = realmAudio, success {
            completion?(realmAudio)
        } else {
            audioRecorder.deleteRecording()
        }
        
        self.audioRecorder = nil
        isRecorderPaused = false
        
        if realmAudio != nil {
            realmAudio = nil
        }
    }
    
    func isRecording() -> Bool {
        return audioRecorder != nil && audioRecorder.isRecording
    }
    
    func isPaused() -> Bool {
        return audioRecorder != nil && isRecorderPaused
    }
    
    func pause() {
        isRecorderPaused = true
        audioRecorder?.pause()
    }
    
}
