//
//  SignalAPIRequests.swift
//  Missito
//
//  Created by Alex Gridnev on 3/9/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss
import URITemplate
import AFNetworking

class APIRequests {
    
    static let BASE_URL = getBaseUrl()
    static let BASE_URL2 = getBaseUrl();
    
//    static let BASE_URL = "http://192.168.2.24:8080";
//    static let BASE_URL2 = "http://192.168.2.24:12448";
    
    private static func getBaseUrl() -> String {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject],
            let baseUrl = dict["API_ENDPOINT"] as? String  {
            
            return baseUrl
        }
        NSLog("No API endpoint URL found")
        fatalError()
    }
    
    static func urlencode(_ str: String) -> String {
        return str.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }
    
    
    // MARK: - Auth API
    
    static func requestOTP(phone: String, _ callback: @escaping (OTPReqResponse?, APIError?)->Void) {
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: BASE_URL + "/otp/request",
                                                        withAuth: false,
                                                        httpMethod: "POST",
                                                        body: prepareOTPRequestBody(phone: phone),
                                                        contentType: "application/x-www-form-urlencoded; charset=utf-8")) {
                                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            
                                                            let (response, apiError) = parseAPIResponse(data: data, response: response, error: error, type: OTPReqResponse.self)
                                                            DispatchQueue.main.async {
                                                                callback(response, apiError)
                                                            }
            }.resume()
        
    }

    static func checkOTP(token: String, code: String, deviceId: Int, _ callback: @escaping (OTPCheckResponse?, APIError?)->Void) {
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: BASE_URL + "/otp/check",
                                                        withAuth: false,
                                                        httpMethod: "POST",
                                                        body: prepareOTPCheckBody(token: token, code: code, deviceId: deviceId),
                                                        contentType: "application/x-www-form-urlencoded; charset=utf-8")) {
                                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            
                                                            let (response, apiError) = parseAPIResponse(data: data, response: response, error: error, type: OTPCheckResponse.self)
                                                            DispatchQueue.main.async {
                                                                callback(response, apiError)
                                                            }
            }.resume()
        
    }

    static func prepareOTPRequestBody(phone: String) -> Data? {
        return ("phone=" + urlencode(Utils.removePlusFrom(phone: phone))).data(using: .utf8)
    }

    static func prepareOTPCheckBody(token: String, code: String, deviceId: Int) -> Data? {
        let deviceIdField = deviceId != 0 ? "&deviceId=" + urlencode(String(deviceId)) : ""
        return ("token=" + urlencode(token) + "&code=" + urlencode(code) + deviceIdField).data(using: .utf8)
    }

    
    // MARK: - Signal API
    
    static func storeIdentity(identityData: IdentityData, _ callback: @escaping (APIError?)->Void) {
        
        guard let jsonData = identityData.toJSON() else {
            NSLog("Can't storeIdentity: identityData.toJSON() failed")
            callback(.badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: URITemplate(template: BASE_URL + "/identity").template,
                                                        withAuth: true,
                                                        httpMethod: "PUT",
                                                        body: Utils.jsonToData(jsonData))) {
            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                        
            let apiError = parseError(response: response, error: error)
            DispatchQueue.main.async {
                callback(apiError)
            }
        }.resume()
        
    }
    
    static func storeSignedPreKey(signedPreKeyData: SignedPreKeyData, _ callback: @escaping (APIError?)->Void) {
        
        guard let jsonData = signedPreKeyData.toJSON() else {
            NSLog("Can't storeSignedPreKey: signedPreKeyData.toJSON() failed")
            callback(.badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: URITemplate(template: BASE_URL + "/signedPreKey").template,
                                                        withAuth: true,
                                                        httpMethod: "PUT",
                                                        body: Utils.jsonToData(jsonData))) {
                (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                           
                let apiError = parseError(response: response, error: error)
                DispatchQueue.main.async {
                    callback(apiError)
                }
        }.resume()
    
    }
    
    static func storeOTPKeys(otpkData: OTPKeysData, _ callback: @escaping (APIError?)->Void) {
        
        guard let jsonData = otpkData.toJSON() else {
            NSLog("Can't storeOTPKeys: otpkData.toJSON() failed")
            callback(.badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: URITemplate(template: BASE_URL + "/otpk").template,
                                                        withAuth: true,
                                                        httpMethod: "POST",
                                                        body: Utils.jsonToData(jsonData))) {
                (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            
                let apiError = parseError(response: response, error: error)
                DispatchQueue.main.async {
                    callback(apiError)
                }
        }.resume()
        
    }
    
    static func requestNewSession(destUid: String, destDeviceId: Int, _ callback: @escaping (NewSessionData?, APIError?)->Void) {
        URLSession.shared.dataTask(with: prepareRequest(urlString: prepareRequestNewSessionUrl(destinationUid: destUid, deviceId: destDeviceId),
                                                        withAuth: true)) {
                (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                
                
                let (newSessionData, apiError) = parseAPIResponse(data: data, response: response, error: error, type: NewSessionData.self)
                DispatchQueue.main.async {
                    callback(newSessionData, apiError)
                }
        }.resume()
        
    }
    static func sendMessage(message: OutgoingMessage, _ callback: @escaping (MessageIdData?, APIError?)->Void) {
        
        guard let jsonData = message.toJSON() else {
            NSLog("Can't sendMessage: message.toJSON() failed")
            callback(nil, .badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: BASE_URL2 + "/p2p",
                                                        withAuth: true,
                                                        httpMethod: "POST",
                                                        body: Utils.jsonToData(jsonData))) {
                                        (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                        let (messageId, apiError) = parseAPIResponse(data: data, response: response, error: error, type: MessageIdData.self)
                                        DispatchQueue.main.async {
                                            callback(messageId, apiError)
                                        }
            }.resume()
    }
    
    static func addContacts(contacts: ContactsUpdateMessage, _ callback: @escaping (APIError?)->Void) {
        //let contactsUpdateMessage = ContactsUpdateMessage(phones: Utils.removePlusFrom(phones: phones))
        guard let jsonData = try? JSONEncoder().encode(contacts) else {
            NSLog("Can't addContacts: message.toJSON() failed")
            callback(.badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: URITemplate(template: BASE_URL2 + "/contacts").template,
                                                        withAuth: true,
                                                        httpMethod: "POST",
                                                        body: jsonData)) {
                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                            let apiError = parseError(response: response, error: error)
                                            DispatchQueue.main.async {
                                                callback(apiError)
                                            }
            }.resume()
    }
    
    static func sendInvites(lang: String, phones: [String], _ callback: @escaping (APIError?)->Void) {
        let phones = Utils.removePlusFrom(phones: phones)
        let inviteRequest = InviteRequest(lang: lang, phones: phones)
        guard let jsonData = inviteRequest.toJSON() else {
            NSLog("Can't send invites: inviteRequest.toJSON() failed")
            callback(.badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: URITemplate(template: BASE_URL2 + "/invite").template,
                                                        withAuth: true,
                                                        httpMethod: "POST",
                                                        body: Utils.jsonToData(jsonData))) {
                                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            let apiError = parseError(response: response, error: error)
                                                            DispatchQueue.main.async {
                                                                callback(apiError)
                                                            }
            }.resume()
    }
    
    static func updateContactsStatus(block: [String], normal: [String], muted: [String], _ callback: @escaping (APIError?)->Void) {
        let block = Utils.removePlusFrom(phones: block)
        let normal = Utils.removePlusFrom(phones: normal)
        let muted = Utils.removePlusFrom(phones: muted)
        guard let jsonData = ContactsBlockStatusUpdateMessage(normal: normal, block: block, muted: muted).toJSON() else {
            NSLog("Can't updateContactsBlockStatus: message.toJSON() failed")
            callback(.badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: BASE_URL2 + "/contacts/status",
                                                        withAuth: true,
                                                        httpMethod: "PUT",
                                                        body: Utils.jsonToData(jsonData))) {
                                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            let apiError = parseError(response: response, error: error)
                                                            DispatchQueue.main.async {
                                                                callback(apiError)
                                                            }
            }.resume()
    }
    
    static func updateMessageStatus(received: [String], seen: [String], _ callback: @escaping (UpdatedMessages?,APIError?)->Void) {
        
        guard let jsonData = MessageStatusRequest(received: received, seen: seen).toJSON() else {
            NSLog("Can't updateMessageStatus: message.toJSON() failed")
            callback(nil, .badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: BASE_URL2 + "/message/status",
                                                        withAuth: true,
                                                        httpMethod: "PUT",
                                                        body: Utils.jsonToData(jsonData))) {
                                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            let (updatedMessages, apiError) = parseAPIResponse(data: data, response: response, error: error, type: UpdatedMessages.self)
                                                            DispatchQueue.main.async {
                                                                callback(updatedMessages, apiError)
                                                            }
            }.resume()
    }
    
    static func updateCloudToken(cloudToken: String, _ callback: @escaping (APIError?)->Void) {
        
        guard let jsonData = CloudTokenUpdate(token: cloudToken).toJSON() else {
            NSLog("Can't updateMessageStatus: message.toJSON() failed")
            callback(.badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: URITemplate(template: BASE_URL2 + "/cloudtoken").template,
                                                        withAuth: true,
                                                        httpMethod: "PUT",
                                                        body: Utils.jsonToData(jsonData))) {
                                                            (data: Data?, response: URLResponse?, error: Error?) -> Void in
                                                            let apiError = parseError(response: response, error: error)
                                                            DispatchQueue.main.async {
                                                                callback(apiError)
                                                            }
            }.resume()
        
    }
    
    static func removeCloudToken(_ callback: @escaping (APIError?)->Void) {
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: prepareRemoveCloudTokenUrl(),
                                                        withAuth: true,
                                                        httpMethod: "DELETE")) {
                                                            (data: Data?, response: URLResponse?, error: Error?) -> Void in
                                                            let apiError = parseError(response: response, error: error)
                                                            DispatchQueue.main.async {
                                                                callback(apiError)
                                                            }
            }.resume()

    }

    static func getProfileSettings(_ callback: @escaping (ProfileSettings?, APIError?)->Void) {
        URLSession.shared.dataTask(with: prepareRequest(urlString: URITemplate(template: BASE_URL2 + "/profile").template,
                                                        withAuth: true)) {
                                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            let (profile, apiError) = parseAPIResponse(data: data, response: response, error: error, type: ProfileSettings.self)
                                                            DispatchQueue.main.async {
                                                                callback(profile, apiError)
                                                            }
            }.resume()
    }
    
    static func getAttachSpec(destUid: String, destDeviceId: Int, fileSize: UInt64, _ callback: @escaping (AttachmentSpec?, APIError?)->Void) {
        URLSession.shared.dataTask(with: prepareRequest(urlString: prepareAttachSpecUrl(destUid:  destUid, destDeviceId: destDeviceId, fileSize: fileSize),
                                                        withAuth: true)) {
                                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            let (attachSpec, apiError) = parseAPIResponse(data: data, response: response, error: error, type: AttachmentSpec.self)
                                                            DispatchQueue.main.async {
                                                                callback(attachSpec, apiError)
                                                            }
            }.resume()
    }
    
    static func uploadFile(filePath: String, spec: AttachmentSpec, progressCallback: @escaping (Float)->(), _ callback: @escaping (APIError?)->Void) {
        let fileInputStream = InputStream(fileAtPath: filePath)
        
        guard fileInputStream != nil else {
            NSLog("Missing file: %@", filePath)
            return
        }
        
        var error: NSError?
        let request = AFHTTPRequestSerializer().multipartFormRequest(withMethod: "POST", urlString: spec.uploadURL, parameters: nil, constructingBodyWith: { (formData) in
            
            for entry in spec.uploadFields {
                formData.appendPart(withForm: entry.value.data(using: .utf8) ?? Data(), name: entry.key)
            }
            formData.appendPart(withForm: "application/octet-stream".data(using: .utf8)!, name: "Content-type")

            let fileName = (filePath as NSString).lastPathComponent
            formData.appendPart(with: fileInputStream, name: "file", fileName: fileName, length: Int64(Utils.getFileSize(path: filePath)),
                                mimeType: "application/octet-stream")
            
        }, error: &error)
        
        let manager = AFURLSessionManager.init(sessionConfiguration: URLSessionConfiguration.default)
        manager.responseSerializer = AFHTTPResponseSerializer()
        
        let uploadTask = manager.uploadTask(withStreamedRequest: request as URLRequest, progress: { (progress) in
            progressCallback(Float(progress.fractionCompleted))
        }) { (response, responseObject, error) in
            if let httpResponse = response as? HTTPURLResponse {
                NSLog("Status code: (\(httpResponse.statusCode))")
            }
            if let error = error {
                if let data = responseObject as? Data {
                    let str = String.init(data: data, encoding: .utf8)
                    NSLog("Resp: " + (str ?? ""))
                }
                NSLog("File upload failed for: %@: %@", filePath, error.localizedDescription)
                callback(APIError.httpError(cause: error))
            } else {
                callback(nil)
            }
        }
        
        uploadTask.resume()
    }
    
    static func downloadFile(url: URL, toFile: URL, progress: ((Progress)->())? = nil , _ callback: @escaping (APIError?) -> Void) {
        let manager = AFURLSessionManager.init(sessionConfiguration: URLSessionConfiguration.default)
        manager.responseSerializer = AFHTTPResponseSerializer()
        
        var request = URLRequest(url: url)
        request.setValue("Bearer " + (CoreServices.authService?.backendToken ?? "nil")!, forHTTPHeaderField: "Authorization")
        
        let downloadTask = manager.downloadTask(with: request as URLRequest,
                                                progress: progress,
                                                destination: { fileURL, response in
                                                    toFile
                                                },
                                                completionHandler: { (response, responseObject, error) in
                                                    if let httpResponse = response as? HTTPURLResponse {
                                                        NSLog("Status code: (\(httpResponse.statusCode))")
                                                    }
                                                    if let error = error {
                                                        NSLog("File download failed for: %@. %@", url.absoluteString, error.localizedDescription)
                                                        callback(APIError.httpError(cause: error))
                                                    } else {
                                                        callback(nil)
                                                    }
        })
        
        downloadTask.resume()
    }
    
    static func attachAndUploadFile(destUid: String, destDeviceId: Int, localFilePath: String, fileSize: UInt64, progressCallback: @escaping (Float)->(), _ completion: @escaping (AttachmentSpec?, APIError?)->()) {
        
        APIRequests.getAttachSpec(destUid: destUid, destDeviceId: destDeviceId, fileSize: fileSize) { (spec, error) in
            guard error == nil else {
                NSLog("Failed to get AttachmentSpec: " + error!.localizedDescription)
                completion(nil, error)
                return
            }
            guard let spec = spec else {
                completion(nil, APIError.unknownError)
                return
            }
            
            APIRequests.uploadFile(filePath: localFilePath, spec: spec,
                                   progressCallback: progressCallback) { error in
                                    if let error = error {
                                        completion(nil, error)
                                    } else {
                                        completion(spec, nil)
                                    }
            }
        }
    }
    
    static func toggleStatusVisibility(visible: Bool, _ callback: @escaping (APIError?)->Void) {
        updateProfileSettings(presenceStatus: visible, messageStatus: nil, callback)
    }
    
    static func allowSendMessageSeenStatus(allow: Bool, _ callback: @escaping (APIError?)->Void) {
        updateProfileSettings(presenceStatus: nil, messageStatus: allow, callback)
    }
    
    static func updateProfileSettings(presenceStatus: Bool?, messageStatus: Bool?, _ callback: @escaping (APIError?)->Void) {
        let jsonData = ProfileSettings(messageStatus: messageStatus, presenceStatus: presenceStatus).toJSON()
        
        guard jsonData != nil else {
            NSLog("Can't updateProfileSettings: ProfileSettings.toJSON() failed")
            callback(.badInputData)
            return
        }
        
        URLSession.shared.dataTask(with: prepareRequest(urlString: URITemplate(template: BASE_URL2 + "/profile").template,
                                                        withAuth: true,
                                                        httpMethod: "PUT",
                                                        body: Utils.jsonToData(jsonData!))) {
                                                            (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
                                                            let apiError = parseError(response: response, error: error)
                                                            DispatchQueue.main.async {
                                                                callback(apiError)
                                                            }
            }.resume()
    }
    
    private static func parseError(response: URLResponse?, error: Swift.Error?) -> APIError? {
        if let error = error {
            NSLog("storeIdentity HTTP request failed: \(error)")
            return .httpError(cause: error)
        } else if let httpResponse = response as? HTTPURLResponse {
            NSLog("HTTP responseCode \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    logout()
                }
                return .httpStatusError(status: httpResponse.statusCode)
            } else {
                return nil
            }
        } else {
            return .unknownError
        }
    }
    
    static func prepareRemoveCloudTokenUrl() -> String {
        let template = URITemplate(template: BASE_URL2 + "/cloudtoken{?deviceId}")
        return template.expand(["deviceId": UIDevice.current.identifierForVendor!.uuidString])
    }
        
    static func prepareRequestNewSessionUrl(destinationUid: String, deviceId: Int) -> String {
        let template = URITemplate(template: BASE_URL2 + "/session{?uid,deviceId}")
        return template.expand(["uid": Utils.removePlusFrom(phone: destinationUid), "deviceId": deviceId])
    }
    
    static func prepareSendMessageUrl(phone: String) -> String {
        let template = URITemplate(template: BASE_URL2 + "/p2p{?phone}")
        return template.expand(["phone": Utils.removePlusFrom(phone: phone)])
    }

    static func prepareAttachSpecUrl(destUid: String, destDeviceId: Int, fileSize: UInt64) -> String {
        let template = URITemplate(template: BASE_URL2 + "/attach{?size,destUid,destDeviceId}")
        return template.expand(["size": fileSize, "destUid": Utils.removePlusFrom(phone: destUid), "destDeviceId": destDeviceId])
    }

    static func prepareRequest(urlString: String, withAuth: Bool, httpMethod: String = "GET", body: Data? = nil, contentType: String? = "application/json; charset=utf-8") -> URLRequest {
        var headers: [String : String] = [:]
        if withAuth {
            if let authToken = CoreServices.authService?.backendToken {
                headers["Authorization"] = "Bearer " + authToken
            }
        }
        return prepareRequest(urlString: urlString, headers: headers, httpMethod: httpMethod, body: body, contentType: contentType)
    }

    static func prepareRequest(urlString: String, headers: [String : String], httpMethod: String = "GET", body: Data? = nil,
                               contentType: String? = "application/json; charset=utf-8") -> URLRequest {
        NSLog("Prepare request for URL: %@", urlString)
        NSLog("Body length \(body?.count ?? 0) ")
        NSLog("Content-type: \(contentType ?? "none") ")
        let url = URL(string: urlString)
        var request: URLRequest = URLRequest(url: url!)
        
        request.httpMethod = httpMethod
        request.timeoutInterval = 60.0
        request.allHTTPHeaderFields = headers;
        if body != nil {
            request.httpBody = body
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    static func parseAPIResponse<T: Gloss.Decodable>(data: Data?,
                                 response: URLResponse?, error: Swift.Error?, type: T.Type) -> (result: T?, apiError: APIError?) {
        if let httpResponse = response as? HTTPURLResponse {
            NSLog("HTTP responseCode \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    logout()
                }
                return (nil, .httpStatusError(status: httpResponse.statusCode))
            }
        }
        
        if let error = error {
            NSLog("HTTP request failed: \(error)")
            return (nil, .httpError(cause: error))
        } else {
            if let result = T(data: data!) {
                return (result, nil)
            } else {
                return (nil, .parseError)
            }
        }
        
    }
    
    //Log out user when response status code is 401 or 403
    private static func logout() {
        // Due to manipulation with UI, next code should be executed on main thread
        DispatchQueue.main.async {
            CoreServices.authService?.logOut()
            let authRootNavigation = UIStoryboard(name: "Auth", bundle: nil).instantiateInitialViewController() as? UINavigationController
            UIApplication.shared.windows.first?.rootViewController = authRootNavigation
        }
    }
}

enum APIError: Swift.Error {
    case httpError(cause: Swift.Error),
    httpStatusError(status: Int),
    parseError,
    badInputData,
    unknownError
    
    var localizedDescription: String {
        get {
            switch self {
            case .httpError(let value):
                return "Network error. " + value.localizedDescription
            case .httpStatusError(let value):
                return "Request error. Http code " + String(value)
            case .parseError:
                return "Could not parse response"
            case .badInputData:
                return "Bad input data"
            default:
                return "Unknown error"
            }
        }
    }
}
