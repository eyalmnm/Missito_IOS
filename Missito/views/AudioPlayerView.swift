//
//  AudioPlayerView.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/24/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class AudioPlayerView: BubbleView {
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var loadingIndicatorView: NVActivityIndicatorView?
    
    private var url: URL?
    private var isPlaying: Bool = false
    private var timer: Timer? = nil
    private var downloadAudio: (()->())?
    var downloadStatus = DownloadStatus.notStarted
    
    private static let playTitle = " " + String.fontAwesomeIcon(name: .play)
    private static let pauseTitle = String.fontAwesomeIcon(name: .pause)
    private static let downloadTitle = String.fontAwesomeIcon(name: .download)
    
    private var direction: ChatMessage.Direction?
    
    enum DownloadStatus: Int {
        case notStarted = -1,
        started = 0,
        finished = 1
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization
        slider.addTarget(self, action: #selector (AudioPlayerView.sliderDidEndSliding), for: [.touchUpInside, .touchUpOutside])
        playButton.tintColor = UIColor.missitoBlue
        playButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 17)
        playButton.setTitle(AudioPlayerView.playTitle, for: .normal)
        NotificationCenter.default.addObserver(self, selector: #selector (AudioPlayerView.recordHasStopped), name: MissitoAudioPlayerManager.ON_STOP_PLAYING_RECORD, object: nil)
        bubbleCornerRadius = 27.0
    }
    
    func recordHasStopped(notification: Notification) {
        if let userInfo = notification.userInfo, let recordUrl = userInfo[MissitoAudioPlayerManager.RECORD_URL_KEY] as? URL {
            if url == recordUrl {
                stop()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func fillEmpty() {
        setupUIFor(time: 0)
        slider.maximumValue = 0
        animationOff()
        self.url = nil
        self.downloadAudio = nil
    }
    
    func fill(for message: ChatMessage, contactPhone: String, _ downloadAudio: (()->())? = nil) {
        guard let audios = message.attachment?.audio, !audios.isEmpty else {
            fillEmpty()
            return
        }
        let audio = audios[0]
        guard let url = Utils.getFileURL(phone: contactPhone, fileName: audio.fileName) else {
            fillEmpty()
            return
        }
        
        self.direction = message.direction
        self.url = url
        self.downloadAudio = downloadAudio
        
        if let ct = MissitoAudioPlayerManager.player?.currentTime, MissitoAudioPlayerManager.playing(url) {
            setupUIFor(time: ct)
            slider.maximumValue = Float(MissitoAudioPlayerManager.player?.duration ?? 0)
        } else {
            resetSliderUI()
        }
        
        if message.progress == nil {
            downloadStatus = isDownloaded() ? .finished : .notStarted
            animationOff()
        } else {
            downloadStatus = .started
            animationOn()
        } 
        updatePlayButton()
    }
    
    func updatePlayButton() {
        switch downloadStatus {
        case .started:
//            playButton.setTitle(nil, for: .normal)
            playButton.setTitle(AudioPlayerView.playTitle, for: .normal)
        case .finished:
            if isPlaying {
                playButton.setTitle(AudioPlayerView.pauseTitle, for: .normal)
            } else {
                playButton.setTitle(AudioPlayerView.playTitle, for: .normal)
            }
        case .notStarted:
            playButton.setTitle(AudioPlayerView.downloadTitle, for: .normal)
        }
    }
    
    func slide() {
        guard MissitoAudioPlayerManager.playing(url) else { return }
        MissitoAudioPlayerManager.player?.currentTime = TimeInterval(round(slider.value))
        currentTimeLabel.text = formatPlaybackTime(MissitoAudioPlayerManager.player?.currentTime ?? 0)
    }
    
    func resetSliderUI() {
        setupUIFor(time: Utils.getAudioRecordDuration(url!), sliderValue: 0.0)
    }
    
    func setupUIFor(time: TimeInterval, sliderValue: TimeInterval? = nil) {
        currentTimeLabel.text = formatPlaybackTime(time)
        slider.setValue(Float(sliderValue ?? time), animated: false)
    }
    
    func formatPlaybackTime(_ interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = ti / 60
        return "\(Int(minutes).format("02")):\(Int(seconds).format("02"))"
    }
    
    func stopUI() {
        playButton.setTitle(AudioPlayerView.playTitle, for: .normal)
        resetSliderUI()
        isPlaying = false
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        stopUI()
    }
    
    private func isDownloaded() -> Bool {
        return FileManager.default.fileExists(atPath: (url?.path ?? ""))
    }
    
    @IBAction func play(_ sender: AnyObject) {
        guard downloadStatus == .finished else {
            if downloadStatus == .notStarted {
                downloadStatus = .started
                animationOn()
                downloadAudio?()
            }
            return
        }
        
        if isPlaying {
            pause()
        } else {
            if !MissitoAudioPlayerManager.playing(url) {
                resetSliderUI()
                MissitoAudioPlayerManager.stop()
                _ = MissitoAudioPlayerManager.prepareToPlay(url)
            }
            slider.maximumValue = Float(MissitoAudioPlayerManager.player?.duration ?? 0)
            MissitoAudioPlayerManager.play()
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(progressUpdate), userInfo: nil, repeats: true)
            isPlaying = true
            playButton.setTitle(AudioPlayerView.pauseTitle, for: .normal)
        }
    }
    
    func pause() {
        timer?.invalidate()
        MissitoAudioPlayerManager.player?.pause()
        isPlaying = false
        playButton.setTitle(AudioPlayerView.playTitle, for: .normal)
    }
    
    func sliderDidEndSliding(_ sender: AnyObject) {
        if !isPlaying && MissitoAudioPlayerManager.playing(url) {
            play(playButton)
        }
    }
    
    @IBAction func slide(_ sender: AnyObject) {
        if isPlaying {
            pause()
        }
        slide()
    }
    
    func progressUpdate() {
        guard MissitoAudioPlayerManager.playing(url) else {
            timer?.invalidate()
            timer = nil
            return
        }
        let timeInterval = MissitoAudioPlayerManager.player?.currentTime ?? TimeInterval()
        let value = Float(timeInterval)
        slider.setValue(value, animated: true)
        currentTimeLabel.text = formatPlaybackTime(timeInterval)
    }
    
    private func animationOn() {
        loadingIndicatorView?.startAnimating()
        if direction == .incoming {
            playButton.tintColor = UIColor.white
        }
    }
    
    private func animationOff() {
        loadingIndicatorView?.stopAnimating()
        playButton.tintColor = UIColor.missitoBlue
    }
}
