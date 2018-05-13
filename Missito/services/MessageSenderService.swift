//
//  MessageSenderService.swift
//  Missito
//
//  Created by Alex Gridnev on 4/6/18.
//  Copyright © 2018 Missito GmbH. All rights reserved.
//

import Foundation
import Contacts
import UIKit

class MessageSenderService: LoadProgressRepository {
    
    static let ADD_NEW_ITEM_NOTIF = Notification.Name(rawValue: "mss_add_new_item")
    static let MARK_SAVED_NOTIF = Notification.Name(rawValue: "mss_mark_saved")
    static let REPORT_ENCR_FAIL_NOTIF = Notification.Name(rawValue: "mss_report_encr_fail")
    static let UPD_MSG_ITEM_NOTIF = Notification.Name(rawValue: "mss_upd_msg_item")
    
    static let MESSAGE_KEY = "message_key"
    static let MESSAGE_ID_KEY = "message_id"
    static let MESSAGE_ID_DATA_KEY = "message_id_data"

    
    // messageId -> progress value
    private var progressDict: [String: Float] = [:]

    private let signalProto = (CoreServices.sharedInstance?.auth?.signalProto)!
    
    private func makeOutgoingMessage(destPhone: String, text: String?, attachment: RealmAttachment?) -> RealmMessage {
        let destDeviceId = ContactsStatusManager.deviceIds[destPhone] ?? 0
        let senderDeviceId = CoreServices.authService?.userDeviceId ?? 0
        let message = RealmMessage(serverMsgId: nil, groupId: nil, threadId: nil,
                            timeSent: UInt64(NSDate().timeIntervalSince1970),
                            senderUid: CoreServices.authService?.userId, senderDeviceId: senderDeviceId,
                            destUid: destPhone, destDeviceId: destDeviceId,
                            msg: text, contentType: nil,
                            incomingStatus: nil, outgoingStatus: .outgoing, attachment: attachment)
        MissitoRealmDbHelper.saveRealmMessage(message)
        return message
    }
    
    private func makeOutgoingMessage(destPhone: String, attachment: RealmAttachment) -> RealmMessage {
        return makeOutgoingMessage(destPhone: destPhone, text: nil, attachment: attachment)
    }
    
    func handleNewAudio(destPhone: String, realmAudio: RealmAudio) {
        if let path = Utils.getFileURL(phone: destPhone, fileName: realmAudio.fileName)?.path {
            let fileSize = Utils.getFileSize(path: path)
            realmAudio.size = Int64(fileSize)
            
            let attachment = RealmAttachment()
            attachment.audio.append(realmAudio)
            
            let realmMessage = self.makeOutgoingMessage(destPhone: destPhone, attachment: attachment)
            
            self.sendWithBinary(message: realmMessage, encryptionKey: realmAudio.secret,
                                localFilePath: path, fileSize: fileSize) { attachmentSpec in
                realmMessage.attachment?.audio[0].link = attachmentSpec.downloadURL
                MissitoRealmDbHelper.write(RealmMessage.self, realmMessage, update: true)
            }
        }

    }
    
    func sendWithBinary(message: RealmMessage, encryptionKey: String, localFilePath: String, fileSize: UInt64,
                        completion: @escaping (AttachmentSpec)->()) {
        guard message.attachment != nil else {
            NSLog("Can't sendWithBinary: no attachment")
            return
        }
        notifyAddMessageItem(message)
        let messageId = message.id
        progressDict[messageId] = 0.0
        
        let destDeviceId = ContactsStatusManager.deviceIds[message.destUid!] ?? 0
        
        EncryptionDownloadHelper.encryptAndUpload(destUid: message.destUid!, destDeviceId: destDeviceId, encryptionKey: encryptionKey, localFilePath: localFilePath, progressCallback: { (progress) in
            DispatchQueue.main.async {
                self.progressDict[messageId] = progress
                self.notifyUpdateMessageItem(messageId: messageId)
                
            }
        }) { (attachmentSpec, error) in
            guard error == nil && attachmentSpec != nil else {
                NSLog("Err ", error?.localizedDescription ?? "empty error")
                // TODO: change UI state to "failed"
                self.progressDict[messageId] = 0.0
                return
            }
            NSLog("sendWithBinary upload OK")
            self.progressDict[messageId] = 1.0
            completion(attachmentSpec!)
            self.send(destPhone: message.destUid!, message: message)
        }
    }
    
    func prepareContactForSend(destPhone: String, contact: CNContact) {
        let realmContact = RealmAttachmentContact(contact)
        
        let attachment = RealmAttachment()
        attachment.contacts.append(realmContact)
        
        let realmMessage = makeOutgoingMessage(destPhone: destPhone, attachment: attachment)
        notifyAddMessageItem(realmMessage)
        
        send(destPhone: destPhone, message: realmMessage)
    }
    
    func prepareImageForSend(destPhone: String, image: UIImage, _ fileName: String, _ dataUTI: String) {
        Utils.saveImage(image: image, imageURL: Utils.getFileURL(phone: destPhone, fileName: fileName)) { filePath in
            if let filePath = filePath {
                image.thumbnail(dataUTI) { thumbnail in
                    if let thumbnail = thumbnail, let base64 = thumbnail.toBase64(dataUTI, quality: CGFloat(0.40)) {
                        
                        let image = RealmImage(fileName: fileName,
                                               link: "received after upload",
                                               size: Int64(Utils.getFileSize(path: filePath)),
                                               secret: EncryptionHelper.generateRandomAES256Key(),
                                               thumbnail: base64)
                        
                        let attachment = RealmAttachment()
                        attachment.images.append(image)
                        
                        let realmMessage = self.makeOutgoingMessage(destPhone: destPhone, attachment: attachment)
                        
                        self.sendWithBinary(message: realmMessage, encryptionKey: image.secret,
                                            localFilePath: filePath, fileSize: UInt64(image.size)) { attachmentSpec in
                                                realmMessage.attachment?.images[0].link = attachmentSpec.downloadURL
                                                MissitoRealmDbHelper.write(RealmMessage.self, realmMessage, update: true)
                        }
                    }
                }
            }
        }
    }
    
    func prepareVideoForSend(destPhone: String, fromURL url: URL) {
        
        let fileName = url.lastPathComponent
        let fileSize = Utils.getFileSize(path: url.path)
        
        let realmVideo = RealmVideo(title: fileName, fileName: fileName,
                                    link: "", size: Int64(fileSize),
                                    secret: EncryptionHelper.generateRandomAES256Key(),
                                    thumbnail: "",
                                    localPath: url.path)
        
        Utils.makeThumbnailFromVideo(url) {
            thumbnail in
            realmVideo.thumbnail = thumbnail ?? ""
            let attachment = RealmAttachment()
            attachment.video.append(realmVideo)
            
            let realmMessage = self.makeOutgoingMessage(destPhone: destPhone, attachment: attachment)
            
            self.sendWithBinary(message: realmMessage, encryptionKey: realmVideo.secret, localFilePath: url.path, fileSize: fileSize) { attachmentSpec in
                realmMessage.attachment?.video[0].link = attachmentSpec.downloadURL
                MissitoRealmDbHelper.write(RealmMessage.self, realmMessage, update: true)
            }
        }
    }
    
    func prepareLocationForSend(destPhone: String, realmLocation: RealmLocation) {
        let attachment = RealmAttachment()
        attachment.locations.append(realmLocation)
        
        let realmMessage = makeOutgoingMessage(destPhone: destPhone, attachment: attachment)
        
        notifyAddMessageItem(realmMessage)
        send(destPhone: destPhone, message: realmMessage)
    }

    func sendTypingMessage(destPhone: String) {
        let emptyMessage = RealmMessage()
        send(destPhone: destPhone, message: emptyMessage, typing: .on)
    }
    
    func sendMessage(destPhone: String, text: String?) {
        if let text = text {
            let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                return
            }
            let message = makeOutgoingMessage(destPhone: destPhone, text: text, attachment: nil)
            
            notifyAddMessageItem(message)
            send(destPhone: destPhone, message: message)
        }
    }

        
    // TODO: use from AuthService also
    private func send(destPhone: String, message: RealmMessage, typing: MessageBody.Typing? = nil) {
        NSLog("send %@", message.id)
        
        let destDeviceId = ContactsStatusManager.deviceIds[destPhone] ?? 0
        
        let msgBody = MessageBody(
            text: message.msg,
            uniqueId: message.uniqueId,
            typing: typing,
            typingStart: UInt64(NSDate().timeIntervalSince1970 * 1000),
            attach: MissitoAttachment.make(from: message.attachment)
        )
        
        if signalProto.sessionExists(forUID: destPhone, deviceId: Int32(destDeviceId)) {
            encryptAndSend(destPhone: destPhone, destDeviceId: destDeviceId, messageBody: msgBody, isPreKey: false, qos: typing != nil ? .transient : .mandatory) { messageIdData in
                self.updateMessage(message, messageId: messageIdData, typing: typing)
            }
        } else {
            APIRequests.requestNewSession(destUid: destPhone, destDeviceId: destDeviceId) { (newSessionData, error) in
                if let error = error {
                    print("startNewSession failed: " + error.localizedDescription)
                } else {
                    print("otpk key id = \(newSessionData!.otpk.keyId)")
                    let r = self.signalProto.buildSession(with: newSessionData, uid: destPhone, deviceId: Int32(destDeviceId))
                    if r == SG_SUCCESS {
                        self.encryptAndSend(destPhone: destPhone, destDeviceId: destDeviceId, messageBody: msgBody, isPreKey: true, qos: typing != nil ? .transient : .mandatory) { messageIdData in
                            self.updateMessage(message, messageId: messageIdData, typing: typing)
                        }
                    } else {
                        // TODO: inspect r value and adapt user message
                        self.notifyReportEncryptionFailure(messageId: message.id)
                    }
                }
            }
            
        }
    }
    
    private func updateMessage(_ message: RealmMessage, messageId: MessageIdData,
                               typing: MessageBody.Typing?) {
        guard typing == nil else {
                return
        }
        message.serverMsgId = messageId.serverMsgId
        message.outgoingStatus = RealmMessage.OutgoingMessageStatus.sent
        MissitoRealmDbHelper.write(RealmMessage.self, message, update: true)
        
        notifyMarkMessageSaved(messageId: message.id, messageIdData: messageId)
    }
    
    // Extract to a helper - to be used from AuthService also
    private func encryptAndSend(destPhone: String, destDeviceId: Int, messageBody: MessageBody, isPreKey: Bool, qos: OutgoingMessage.QoS, _ completion: @escaping (MessageIdData)->()) {
        var plaintext: String?
        if let json = messageBody.toJSON() {
            if let str = Utils.jsonToString(json) {
                plaintext = str
                NSLog("Message Body JSON: " + (plaintext ?? ""))
            } else {
                NSLog("Couldn't serialize message body to JSON!")
            }
        }
        
        let brokerMessage = signalProto.encryptMessage(plaintext, destUid: destPhone, destDeviceId: Int32(destDeviceId))
        if let data = brokerMessage?.body, let type = brokerMessage?.messageType {
            APIRequests.sendMessage(message: OutgoingMessage.init(destUid: destPhone, destDeviceId: destDeviceId,
                                                                  data: data, type: type, qos: qos)) {
                                                                    (messageId, error) in
                                                                    if let error = error {
                                                                        NSLog(error.localizedDescription)
                                                                    } else if let messageId = messageId {
                                                                        completion(messageId)
                                                                    }
            }
        }
    }
    
    func getLoadProgress(messageId: String) -> Float? {
        return progressDict[messageId]
    }
    
    func notifyUpdateMessageItem(messageId: String) {
        NotificationCenter.default.post(name: MessageSenderService.UPD_MSG_ITEM_NOTIF, object: nil, userInfo: [MessageSenderService.MESSAGE_ID_KEY : messageId])
    }
    
    func notifyAddMessageItem(_ message: RealmMessage) {
        NotificationCenter.default.post(name: MessageSenderService.ADD_NEW_ITEM_NOTIF, object: nil, userInfo: [MessageSenderService.MESSAGE_KEY : message])
    }
    
    func notifyMarkMessageSaved(messageId: String, messageIdData: MessageIdData) {
        NotificationCenter.default.post(name: MessageSenderService.MARK_SAVED_NOTIF, object: nil, userInfo: [
            MessageSenderService.MESSAGE_ID_KEY : messageId,
            MessageSenderService.MESSAGE_ID_DATA_KEY : messageIdData])
    }
    
    func notifyReportEncryptionFailure(messageId: String) {
        NotificationCenter.default.post(name: MessageSenderService.REPORT_ENCR_FAIL_NOTIF, object: nil, userInfo: [MessageSenderService.MESSAGE_ID_KEY : messageId])
    }
}
