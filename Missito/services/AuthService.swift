import Foundation
import UIKit
import JWT
import Contacts
import MQTTClient
import FirebaseMessaging

class AuthService {
    
    static let LOCAL_MESSAGE_STATUS_UPDATE_NOTIF = Notification.Name(rawValue: "local_msg_status_update")
    static let MESSAGE_STATUS_KEY = "msg_status_key"
    
    var authState: AuthState = .loggedOut
    var backendToken: String?
    
    var senderService: MessageSenderService?
    var downloaderService: DownloadService?
    var signalProto: SignalProto?
    let brokerConnection: BrokerConnection
    var reachability: Reachability?
    
    var profileSettings: ProfileSettings?
    var userId: String?
    var userDeviceId: Int = 0
    var sendingMsgIds = Set<String>()
    
    init?(endpoint: String) {
        brokerConnection = BrokerConnection(host: endpoint)
        userId = KeyChainHelper.getUserId()
        backendToken = KeyChainHelper.getUserToken()
        if userId != nil && backendToken != nil {
            authState = .loggedIn
            userDeviceId = DefaultsHelper.getDeviceId(for: userId!)
        } else {
            userId = nil
            backendToken = nil
        }
    }
    
    func setup() {
        if userId != nil && backendToken != nil {
            initForUser()
        }
    }
    
    func getSignalProto() -> SignalProto? { return self.signalProto }

    func logOut() {
        removeCloudToken()
        reachability?.stopNotifier()
        KeyChainHelper.removeUserAuthData()
        brokerConnection.disconnect()
        authState = .loggedOut
    }
    
    private func initForUser() {
        signalProto = SignalProto(forUserId: userId)
        MissitoRealmDB.setupRealm(uid: userId)
        
        senderService = MessageSenderService()
        downloaderService = DownloadService()
        
        // TODO: do this in background
        signalProto!.setup()
        print("Identity public key: " + signalProto!.identityPublicKey)
        
        self.brokerConnection.setClient(signalProto: signalProto!)
    
        ContactsManager.fetchContacts()
        
        if (DefaultsHelper.getReportKeysFlag()) {
            reportSignalKeys()
        } else {
            // Temporary hack for https://github.com/ckrey/MQTT-Client-Framework/issues/312
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.brokerConnection.connect(userId: self.userId!, deviceId: self.userDeviceId, token: self.backendToken!)
            }
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.mqttConnectionStateChanged(notification:)),
                                               name: MQTTMissitoClient.CONN_STATE_UPD_NOTIF, object: nil)
        
        self.setupReachabilityListener()
        self.updateCloudToken()
        self.getProfileSettings()
    }
    
    func verify(phone: String, token: String, code: String, completion: @escaping (_ error: APIError?)->Void) {
        authState = .loggingIn
        KeyChainHelper.removeUserAuthData()
        backendToken = nil
        let deviceId = DefaultsHelper.getDeviceId(for: phone)
        APIRequests.checkOTP(token: token, code: code, deviceId: deviceId) { (response, error) in
            if let error = error {
                self.authState = .loggedOut
                completion(error)
            } else if let response = response {
                // Trying to decode response token and extract userID and deviceID | token example: 37368930662_197
                let subject = (try? JWT.decode(response.token, algorithms: [], verify: false).valueForKeyPath(keyPath: "sub")) as? String
                if subject != nil, case let components = subject!.components(separatedBy: "_"), components.count == 2, let phoneNumber = components.first, let deviceId = Int(components.last!) {
                    self.userDeviceId = deviceId
                    self.backendToken = response.token
                    self.userId = Utils.fixPhoneFormat(phoneNumber)
                    
                    DefaultsHelper.saveDeviceId(for: phone, deviceId)
                    KeyChainHelper.saveUserAuthData(userId: self.userId!, token: response.token)
                    self.authState = .loggedIn
                    self.initForUser()
                    completion(nil)
                } else {
                    NSLog("Error while getting userID and deviceID from subject. %@", subject == nil ? "Error: Subject is nil" : "")
                    self.authState = .loggedOut
                    completion(.parseError)
                }
            } else {
                print("Error: checkOTP returned empty response and error")
                self.authState = .loggedOut
                completion(.unknownError)
            }
        }
    }
    
    private func reportSignalKeys() {
        self.reportIdentityKey()
    }
    
    private func reportIdentityKey() {
        let identityData = IdentityData(registrationId: signalProto!.registrationId, identityPublicKey: signalProto!.identityPublicKey)
        APIRequests.storeIdentity(identityData: identityData) { (error) in
            if let error = error {
                print("storeIdentity failed: " + error.localizedDescription)
            } else {
                self.reportSignedPreKey()
            }
        }
    }
    
    private func reportSignedPreKey() {
        let signedPreKeyData = SignedPreKeyData(keyId: signalProto!.signedPreKeyId,
                                                key: signalProto!.signedPreKeyPublicKey,
                                                keySignature: signalProto!.signedPreKeySignature)
        APIRequests.storeSignedPreKey(signedPreKeyData: signedPreKeyData, { (error) in
            if let error = error {
                print("storeIdentity failed: " + error.localizedDescription)
            } else {
                self.reportOTPKeys()
            }
        })
    }
    
    private func reportOTPKeys() {
        let startId: UInt32 = UInt32((DefaultsHelper.getLastReportedOtpkId()) + 1)
        
                let otpkData = OTPKeysData(startId: startId, keys: signalProto!.getOtpKeys(Int32(startId)))
                APIRequests.storeOTPKeys(otpkData: otpkData) { (error) in
                    if let error = error {
                        print("reportOTPKeys failed: " + error.localizedDescription)
                    } else {
                        self.brokerConnection.connect(userId: self.userId!, deviceId: self.userDeviceId, token: self.backendToken!)
                        DefaultsHelper.saveReportKeysFlag(false)
                        // TODO: for debugging for now
        //                self.startNewSession(destinationUid: self.userId == "1111" ? "2222" : "1111")
                    }
                }
    }
    
    private func startNewSession(destUid: String, destDeviceId: Int) {
        APIRequests.requestNewSession(destUid: destUid, destDeviceId: destDeviceId) { (newSessionData, error) in
            if let error = error {
                print("startNewSession failed: " + error.localizedDescription)
            } else {
                print(newSessionData!)
            }
        }
    }

    private func resendOutgoingMessages() {
        if let realmMessages = MissitoRealmDbHelper.fetch(type: RealmMessage.self, condition: String.init(format: "outgoingStatusStr = '%@'", RealmMessage.OutgoingMessageStatus.outgoing.rawValue))?.sorted(byKeyPath: "timeSent", ascending: true) {
            for msg in realmMessages {
                if !sendingMsgIds.contains(msg.id) {
                    send(message: msg, realmMessages.last?.id == msg.id)
                }
            }
        }
    }
    
    func send(message: RealmMessage, _ isLast: Bool = false) {
        NSLog("send id=%@ status=%@ serverId=%@", message.id, message.outgoingStatusStr ?? "no-status", message.serverMsgId ?? "none")
        sendingMsgIds.insert(message.id)
        let timeSent = Date.init(timeIntervalSince1970: NSDate().timeIntervalSince1970)
        if signalProto!.sessionExists(forUID: message.destUid, deviceId: Int32(message.destDeviceId)) {
            encryptAndSend(message: message, isPreKey: false, timeSent)
        } else {
            APIRequests.requestNewSession(destUid: message.destUid!, destDeviceId: message.destDeviceId) { (newSessionData, error) in
                if let error = error {
                    print("startNewSession failed: " + error.localizedDescription)
                    self.sendingMsgIds.remove(message.id)
                } else {
                    print("otpk key id = \(newSessionData!.otpk.keyId)")
                    let r = self.signalProto!.buildSession(with: newSessionData, uid: message.destUid, deviceId: Int32(message.destDeviceId))
                    if r == SG_SUCCESS {
                        self.encryptAndSend(message: message, isPreKey: true, timeSent)
                    } else {
                        // TODO: show user message
                        NSLog("Can't encrypt message " + message.id)
                        self.sendingMsgIds.remove(message.id)
                    }
                }
            }
            
        }
    }
    
    private func encryptAndSend(message: RealmMessage, isPreKey: Bool, _ timeSent: Date) {
        let msgBody = MessageBody(text: message.msg, uniqueId: message.uniqueId, typingStart: 0, attach: MissitoAttachment.make(from: message.attachment))
        var plaintext: String?
        if let json = msgBody.toJSON() {
            if let str = Utils.jsonToString(json) {
                plaintext = str
                NSLog("Message Body JSON: " + (plaintext ?? ""))
            } else {
                NSLog("Couldn't serialize message body to JSON!")
            }
        }
        
        let brokerMessage = signalProto!.encryptMessage(plaintext, destUid: message.destUid, destDeviceId: Int32(message.destDeviceId))
        if let data = brokerMessage?.body, let type = brokerMessage?.messageType {
            
            APIRequests.sendMessage(message: OutgoingMessage(destUid: message.destUid!, destDeviceId: message.destDeviceId,
                                                             data: data, type: type, qos: .mandatory)) {
                                        (messageId, error) in

                                        self.sendingMsgIds.remove(message.id)
                                        
                                        if let error = error {
                                            NSLog(error.localizedDescription)
                                        } else {
                                            NSLog("Sent message: messageID = %@, msg = %@", messageId?.serverMsgId ?? "nil", message.msg ?? "nil")
                                            MissitoRealmDbHelper.markOutgoingMessageAsSent(message, serverId: messageId!.serverMsgId, timeSent: timeSent)
                                            NotificationCenter.default.post(name: AuthService.LOCAL_MESSAGE_STATUS_UPDATE_NOTIF, object: nil, userInfo: [AuthService.MESSAGE_STATUS_KEY : LocalMessageStatus(message.id, messageId?.serverMsgId ?? "no-server-id", .sent, timeSent)])
                                        }
                }
        } else {
            self.sendingMsgIds.remove(message.id)
        }
    }
    
    private func getProfileSettings() {
        APIRequests.getProfileSettings() { (profileSettings, error) in
            if let error = error {
                NSLog("Could not get: " + error.localizedDescription)
            } else {
                self.profileSettings = profileSettings
            }
        }
    }

    func updateCloudToken() {
        guard authState == .loggedIn else {
            return
        }
        if let cloudToken = Messaging.messaging().fcmToken {
            APIRequests.updateCloudToken(cloudToken: cloudToken, { error in
                if let error = error {
                    print("Couldn't update cloud token: " + error.localizedDescription)
                }
            })
        }
    }
    
    func removeCloudToken() {
        guard authState == .loggedIn else {
            return
        }
        
        APIRequests.removeCloudToken() { error in
            if let error = error {
                print("Couldn't remove cloud token: " + error.localizedDescription)
            }
        }
    }
    
    private func setupReachabilityListener() {
        reachability = Reachability()
        
        if reachability != nil {
            reachability!.whenReachable = { reachability in
                // this is called on a background thread, but UI updates must
                // be on the main thread
                DispatchQueue.main.async {
                    if reachability.isReachableViaWiFi {
                        print("Reachability: Reachable via WiFi")
                    } else {
                        print("Reachability: Reachable via Cellular")
                    }
                }
            }
            reachability!.whenUnreachable = { reachability in
                // this is called on a background thread, but UI updates must
                // be on the main thread
                DispatchQueue.main.async {
                    ContactsStatusManager.setAllOffline()
                    print("Reachability: Not reachable")
                }
            }
        
            do {
                try reachability!.startNotifier()
            } catch {
                print("Reachability: Unable to start notifier")
            }
        } else {
            print("Reachability: Reachability() returned nil")
        }
    }
    
    @objc func mqttConnectionStateChanged(notification: Notification) {
        if UIApplication.shared.applicationState != .active {
            return
        }
        
        if let userInfo = notification.userInfo, let mqttState = userInfo[MQTTMissitoClient.CONNECTION_STATE_KEY] as? MQTTSessionManagerState {
            NSLog("MQTT UIApplication.shared.applicationState == active")
            if mqttState == .connected {
                NSLog("MQTT self.resendOutgoingMessages()")
                resendOutgoingMessages()
            }
        }
    }
    
    enum AuthState {
        case loggingIn
        case loggedOut
        case loggedIn
    }

}

