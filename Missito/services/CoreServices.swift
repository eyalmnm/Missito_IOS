//
//  CoreServices.swift
//  Missito
//
//  Created by George Poenaru on 08/12/2016.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

final class CoreServices {
    
    var auth: AuthService?

    static var sharedInstance: CoreServices?
    
    func setup() {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject], let endpoint = dict["BROKER_HOST"] as? String else  { return  }
        
        guard let authService = AuthService(endpoint: endpoint) else { return }
        auth = authService
        auth?.setup()
    }
    
    static var authService: AuthService? {
        return CoreServices.sharedInstance?.auth
    }
    
    static var senderService: MessageSenderService? {
        return CoreServices.sharedInstance?.auth?.senderService
    }

    static var downloadService: DownloadService? {
        return CoreServices.sharedInstance?.auth?.downloaderService
    }

    static var signalProto: SignalProto? { return CoreServices.authService?.getSignalProto() }
    
    static func setup() {
        sharedInstance = CoreServices()
        sharedInstance?.setup()
    }
}
