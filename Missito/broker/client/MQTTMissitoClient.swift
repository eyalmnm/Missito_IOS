//
//  MQTTMissitoClient.swift
//  Missito
//
//  Created by Alex Gridnev on 3/9/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import MQTTClient
import Gloss

class MQTTMissitoClient: NSObject, MQTTSessionManagerDelegate
//, MQTTSessionDelegate
{
    static let CONN_STATE_UPD_NOTIF = NSNotification.Name(rawValue: "MQTTMissitoClient_conn_state_update")
    static let NEW_MSG_NOTIF = NSNotification.Name(rawValue: "new_message")
    static let MESSAGE_STATUS_UPDATE_NOTIF = NSNotification.Name(rawValue: "message_status_udpate")
    
    private static let MESSAGE_TOPIC_BASE = "message/"
    private static let STATUS_TOPIC_BASE = "status/"
    private static let MESSAGE_STATUS_UPDATE_TOPIC_BASE = "messageStatus/"
    private var messageTopic = ""
    private var statusTopic = ""
    private var messageStatusTopic = ""
    
    static let MESSAGE_KEY = "message"
    static let DECRYPTED_KEY = "decrypted"
    static let MISSITO_MESSAGE_KEY = "missito_message"
    static let MESSAGE_STATUS_KEY = "message_status"
    static let CONNECTION_STATE_KEY = "connection_state"
    
    var manager: MQTTSessionManager?
    var signalProto: SignalProto
    var connectionParams: MQTTConnectionParams?
    var connectionState = MQTTSessionManagerState.closed
    
    let host: String
    let port: Int
    
    init(host: String, port: Int, signalProto: SignalProto) {
        self.host = host
        self.port = port
        self.signalProto = signalProto
    }
    
    func start(userId: String, deviceId: Int, token: String) {
        guard manager == nil else {
            NSLog("MQTT client is already started")
            return
        }
        let clientId = Utils.removePlusFrom(phone: userId) + "_" + String(deviceId)
        NSLog("Start MQTT connections, clientId: " + clientId + " token: " + token)
        
        connectionParams = MQTTConnectionParams(host: host, port: port, login: clientId, clientId: clientId)
        
        manager = MQTTSessionManager.init(persistence: false, maxWindowSize: 16,
                                          maxMessages: 1024, maxSize: 64 * 1024 * 1024,
                                          connectInForeground: false, queue: DispatchQueue.main)
        
        manager?.delegate = self
        messageStatusTopic = MQTTMissitoClient.MESSAGE_STATUS_UPDATE_TOPIC_BASE + clientId
        messageTopic = MQTTMissitoClient.MESSAGE_TOPIC_BASE + clientId
        statusTopic = MQTTMissitoClient.STATUS_TOPIC_BASE + clientId
        manager?.subscriptions = [messageTopic: NSNumber(value: MQTTQosLevel.exactlyOnce.rawValue),
                                  statusTopic: NSNumber(value: MQTTQosLevel.exactlyOnce.rawValue),
                                  messageStatusTopic: NSNumber(value: MQTTQosLevel.exactlyOnce.rawValue)]
        manager?.connect(to: connectionParams!.host,
                         port: connectionParams!.port,
                         tls: Bundle.main.object(forInfoDictionaryKey: "BROKER_TLS") as! Bool,
                         keepalive: 60,
                         clean: true,
                         auth: true,
                         user: connectionParams!.login,
                         pass: token,
                         willTopic: "will_topic",
                         will: "offline".data(using: .utf8),
                         willQos: .exactlyOnce,
                         willRetainFlag: false,
                         withClientId: connectionParams!.clientId)
        manager?.addObserver(self, forKeyPath: #keyPath(MQTTSessionManager.state), options: [], context: nil)
    }
    
    func disconnect() {
        if let manager = manager {
            manager.removeObserver(self, forKeyPath: #keyPath(MQTTSessionManager.state))
            manager.disconnect()
            connectionState = .closed
        }
        manager = nil
    }
    
    deinit {
        disconnect()
    }
    
    private func processNew(messageBody: MessageBody, incomingMessage: IncomingMessage, realmMessage: RealmMessage) {
        
        if MissitoRealmDbHelper.containsMessage(uniqueId: messageBody.uniqueId) {
            MissitoRealmDbHelper.updateServerMsgId(uniqueId: messageBody.uniqueId, serverMsgId: incomingMessage.serverMsgId)
            return
        }
        
        realmMessage.fill(incomingMessage: incomingMessage,
                          body: messageBody,
                          incomingStatus: .received,
                          destUid: CoreServices.authService?.userId,
                          destDeviceId: CoreServices.authService?.userDeviceId ?? 0)
        
        if !messageBody.isTyping() {
            MissitoRealmDbHelper.saveRealmMessage(realmMessage)
            MissitoRealmDbHelper.updateUnreadMessagesCounter(for: incomingMessage.senderUid)
        } else if !messageBody.isValidTyping() {
            return
        }
        
        let missitoMessage = MissitoMessage(id: realmMessage.id, body: messageBody, incomingMessage: incomingMessage)
        NotificationCenter.default.post(name: MQTTMissitoClient.NEW_MSG_NOTIF, object: nil, userInfo: [MQTTMissitoClient.MISSITO_MESSAGE_KEY: missitoMessage])
    }
    
    func handleMessage(_ data: Data!, onTopic topic: String!, retained: Bool) {
        NSLog("handleMessage")
        NSLog("Received \(data) on:\(topic) r\(retained)")
        if let dataStr = String(data: data, encoding: .utf8) {
            NSLog("Received data as string: %@", dataStr)
        }
        if topic == messageTopic {
            if let incomingMessage = IncomingMessage(data: data) {
                
                let realmMessage = RealmMessage.empty()
                
                _ = signalProto.decryptIncomingMessage(incomingMessage, decryptionCallback: { (data) in
                    if let data = data, let messageBody = MessageBody(data: data) {
                        self.processNew(messageBody: messageBody, incomingMessage: incomingMessage, realmMessage: realmMessage)
                    }
                })
                self.updateMessageStatus(realmMessage.id, incomingMessage.serverMsgId)
                
            } else {
                NSLog("Couldn't parse IncomingMessage/decrypt IncomingMessage/decrypted message has encoding different from UTF-8")
            }
        } else if topic == statusTopic {
            if let csu = StatusMessage(data: data) {
                if csu.msgType == "logout" {
                    DispatchQueue.main.async {
                        CoreServices.authService?.logOut()
                        
                        let authRootNavigation = UIStoryboard(name: "Auth", bundle: nil).instantiateInitialViewController() as? UINavigationController
                        UIApplication.shared.windows.first?.rootViewController = authRootNavigation
                    }
                } else {
                    ContactsStatusManager.update(csu.msg!)
                }
            } else {
                NSLog("Couldn't parse ContactsStatusUpdate message")
            }
        } else if topic == messageStatusTopic {
            if let messageStatus = MessageStatus(data: data) {
                MissitoRealmDbHelper.updateMessageOutgoingStatus(withServerId: messageStatus.serverMsgId, status: RealmMessage.OutgoingMessageStatus(rawValue: messageStatus.status)!)
                NotificationCenter.default.post(name: MQTTMissitoClient.MESSAGE_STATUS_UPDATE_NOTIF, object: nil, userInfo: [MQTTMissitoClient.MESSAGE_STATUS_KEY : messageStatus])
            } else {
                NSLog("Couldn't parse messageStatus message")
            }
        }
    }
    
    func notifyNewConnState() {
        let userInfo: Dictionary<AnyHashable, Any> = [MQTTMissitoClient.CONNECTION_STATE_KEY: connectionState]
        NotificationCenter.default.post(name: MQTTMissitoClient.CONN_STATE_UPD_NOTIF, object: nil, userInfo: userInfo)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let manager = object as? MQTTSessionManager {
            connectionState = manager.state
            NSLog("MQTT: " + MQTTMissitoClient.toString(connectionState: connectionState))
            if (manager.lastErrorCode != nil) {
                NSLog("MQTT last error: %@", manager.lastErrorCode.localizedDescription)
            }
            notifyNewConnState()
        }
    }
    
    func sendMessage(_ message: BrokerMessage, to uid: String) {
        let data = Utils.jsonToData(message.toJSON()!)
        manager!.send(data, topic: uid, qos: .exactlyOnce, retain: false)
    }
    
    func updateMessageStatus(_ localMsgId: String, _ serverMsgId: String) {
        APIRequests.updateMessageStatus(received: [serverMsgId], seen: []) {
            (updatedMessages, apiError) in
            if let _ = apiError {
                NSLog("Could not confirm message received %@", serverMsgId)
            } else {
                if let _ = MissitoRealmDbHelper.getMessage(with: localMsgId) {
                    if let updated = updatedMessages?.updated, updated.contains(serverMsgId) {
                        MissitoRealmDbHelper.setIncomingMessageStatus(localMsgId, RealmMessage.IncomingMessageStatus.receivedAck)
                    } else {
                        MissitoRealmDbHelper.setIncomingMessageStatus(localMsgId, RealmMessage.IncomingMessageStatus.failed)
                        NSLog("Not allowed to confirm message as received: %@", localMsgId)
                    }
                }
            }
        }
    }
    
    class MQTTConnectionParams {
        let host: String
        let port: Int
        let login: String
        let clientId: String
        
        init(host: String, port: Int, login: String, clientId: String) {
            self.host = host
            self.port = port
            self.clientId = clientId
            self.login = login
        }
    }
    
    static func toString(connectionState: MQTTSessionManagerState) -> String {
        let names = ["starting", "connecting", "error", "connected", "closing", "closed"]
        return names[Int(connectionState.rawValue)]
    }
}
