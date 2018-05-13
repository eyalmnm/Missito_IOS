//
//  DownloadService.swift
//  Missito
//
//  Created by Alex Gridnev on 4/12/18.
//  Copyright © 2018 Missito GmbH. All rights reserved.
//

import Foundation

// TODO: bounding DownloadService to ChatMessage interface doesn't feel right
// can we do something about that?
class DownloadService: LoadProgressRepository {
    
    static let DOWNLOAD_FINISH_NOTIF = Notification.Name(rawValue: "ds_download_finish")
    
    static let URL_KEY = "url_key"
    static let ERROR_KEY = "error_key"
    static let MESSAGE_ID_KEY = "message_id_key"

    // messageId -> progress value
    private var progressDict: [String: Float] = [:]
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadService.onNewMessage(notification:)),
                                               name: MQTTMissitoClient.NEW_MSG_NOTIF, object: nil)
    }
    
    @objc func onNewMessage(notification: Notification) {
        guard CoreServices.authService?.reachability?.isReachableViaWiFi ?? false else {
            return
        }
        if let userInfo = notification.userInfo as Dictionary<AnyHashable, Any>? {
            if let msg = userInfo[MQTTMissitoClient.MISSITO_MESSAGE_KEY] as? MissitoMessage {
                let senderPhone = msg.incomingMessage.senderUid
                if let contact = ContactsManager.getContact(phone: senderPhone) {
                    let message = IncomingChatMessage(missitoMessage: msg, senderContact: contact)
                    if let attach = message.attachment {
//                        if (!attach.video.isEmpty) {
//                            downloadVideoFile(senderPhone: senderPhone, message: message)
//                        }
                        if (!attach.images.isEmpty) {
                            downloadImageFile(senderPhone: senderPhone, message: message)
                        }
//                        if (!attach.audio.isEmpty) {
//                            downloadAudioFile(senderPhone: senderPhone, message: message)
//                        }
                    }
                }
            }
        }
    }
    
    func downloadVideoFile(senderPhone: String, message: ChatMessage) {
        guard let messageId = message.id else {
            NSLog("downloadVideoFile failed: can't download data for a message without an ID")
            return
        }
        guard let attachment = message.attachment, !attachment.video.isEmpty else {
            NSLog("downloadVideoFile failed: no video attachment in message")
            return
        }
        guard progressDict[messageId] == nil else {
            NSLog("Attachment download for messgeId=%@ already in progress", messageId)
            return
        }
        let video = attachment.video[0]
        if let fileURL = Utils.getFileURL(phone: senderPhone, fileName: video.fileName),
            let downloadURL = URL(string: APIRequests.BASE_URL2 + video.link) {
            progressDict[messageId] = 0.0
            EncryptionDownloadHelper.downloadAndDecrypt(encryptionKey: video.secret, url: downloadURL, destFileUrl: fileURL) {
                (error) in
                if let error = error {
                    NSLog("Failed to download video from %@. %@", downloadURL.absoluteString, error.localizedDescription)
                } else {
                    //After download is finished update localPath parameter of used RealmVideo
                    video.updateLocalPath(fileURL.path)
                }
                self.progressDict[messageId] = nil
                self.notifyDownloadEnd(messageId: messageId, url: fileURL, error: error)
            }
        } else {
            NSLog("Failed to download image: couldn't create fileURL with last path component equals to %@", video.fileName)
            notifyDownloadEnd(messageId: messageId, url: nil, error: DownloadError.urlError)
        }
    }
    
    func downloadImageFile(senderPhone: String, message: ChatMessage) {
        guard let messageId = message.id else {
            NSLog("downloadImageFile failed: can't download data for a message without an ID")
            return
        }
        guard let attachment = message.attachment, !attachment.images.isEmpty else {
            NSLog("downloadImageFile failed: no image attachment in message")
            return
        }
        guard progressDict[messageId] == nil else {
            NSLog("Attachment download for messgeId=%@ already in progress", messageId)
            return
        }
        let image = attachment.images[0]
        if let fileURL = Utils.getFileURL(phone: senderPhone, fileName: image.fileName),
            let downloadURL = URL(string: APIRequests.BASE_URL2 + image.link) {
            progressDict[messageId] = 0.0
            EncryptionDownloadHelper.downloadAndDecrypt(encryptionKey: image.secret, url: downloadURL, destFileUrl: fileURL) {
                (error) in
                if let error = error {
                    NSLog("Failed to download image from %@. %@", downloadURL.absoluteString, error.localizedDescription)
                }
                self.progressDict[messageId] = nil
                self.notifyDownloadEnd(messageId: messageId, url: fileURL, error: error)
            }
        } else {
            NSLog("Failed to download image: couldn't create fileURL with last path component equals to %@", image.fileName)
            notifyDownloadEnd(messageId: messageId, url: nil, error: DownloadError.urlError)
        }
    }
    
    func downloadAudioFile(senderPhone: String, message: ChatMessage) {
        guard let messageId = message.id else {
            NSLog("downloadAudio failed: can't download data for a message without an ID")
            return
        }
        guard let attachment = message.attachment, !attachment.audio.isEmpty else {
            NSLog("downloadAudio failed: no audio attachment in message")
            return
        }
        guard progressDict[messageId] == nil else {
            NSLog("Attachment download for messgeId=%@ already in progress", messageId)
            return
        }
        let audio = attachment.audio[0]
        if let fileURL = Utils.getFileURL(phone: senderPhone, fileName: audio.fileName) {
            if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: nil) {
                notifyDownloadEnd(messageId: messageId, url: fileURL, error: nil)
                return
            }
            
            let audioURL = URL(string: APIRequests.BASE_URL2 + audio.link)!
            progressDict[messageId] = 0.0
            EncryptionDownloadHelper.downloadAndDecrypt(encryptionKey: audio.secret, url: audioURL, destFileUrl: fileURL, { (error) in
                if let error = error {
                    NSLog("Failed to download %@. %@", audioURL.absoluteString, error.localizedDescription)
                } else if let audioURL = Utils.getFileURL(phone: senderPhone, fileName: audio.fileName) {
                    if FileManager.default.fileExists(atPath: audioURL.path) {
                        MissitoRealmDbHelper.updateAudioMessage(messageId: messageId, audio: audio)
                    }
                }
                self.progressDict[messageId] = nil
                self.notifyDownloadEnd(messageId: messageId, url: fileURL, error: error)
            })
        } else {
            self.notifyDownloadEnd(messageId: messageId, url: nil, error: DownloadError.urlError)
        }
    }
    
    private func notifyDownloadEnd(messageId: String, url: URL?, error: Error?) {
        var userInfo: [AnyHashable: Any] = [DownloadService.MESSAGE_ID_KEY : messageId]
        if let url = url {
            userInfo[DownloadService.URL_KEY] = url
        }
        if let error = error {
            userInfo[DownloadService.ERROR_KEY] = error
        }
        NotificationCenter.default.post(name: DownloadService.DOWNLOAD_FINISH_NOTIF, object: nil, userInfo: userInfo)
    }
    
    func getLoadProgress(messageId: String) -> Float? {
        return progressDict[messageId]
    }
    
    enum DownloadError: Swift.Error {
        case unknown
        case urlError
        
        var localizedDescription: String {
            get {
                switch self {
                case .unknown:
                    return "Unknown download error"
                case .urlError:
                    return "Bad url or can't construct url"
                }
            }
        }
    }
    
}
