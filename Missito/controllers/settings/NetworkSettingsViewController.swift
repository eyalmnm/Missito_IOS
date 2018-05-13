//
//  NetworkSettingsViewController.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/18/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import MQTTClient
import UIKit

class NetworkSettingsViewController: UIViewController {
    
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var apiUrlLabel: UILabel!
    @IBOutlet weak var mqttIpLabel: UILabel!
    @IBOutlet weak var mqttLoginLabel: UILabel!
    @IBOutlet weak var mqttClientIdLabel: UILabel!
    @IBOutlet weak var mqttStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkSettingsViewController.onMqttConnUpdate(notification:)),
                                               name: MQTTMissitoClient.CONN_STATE_UPD_NOTIF, object: nil)
        
        let gAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "0"
        let gAppBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "0"
        
        appVersionLabel.text = String(format: "Missito v%@ (%@)", gAppVersion as! String, gAppBuild as! String)
        apiUrlLabel.text = "API URL: " + APIRequests.BASE_URL;
        
        let connectionParams = CoreServices.authService?.brokerConnection.mqttClient?.connectionParams
        
        mqttIpLabel.text = "MQTT host: " + (connectionParams?.host ?? "none")
        mqttLoginLabel.text = "MQTT login: " + (connectionParams?.login ?? "none")
        mqttClientIdLabel.text = "MQTT clientId: " + (connectionParams?.clientId ?? "none")
        mqttStatusLabel.text = "MQTT status: " + MQTTMissitoClient.toString(connectionState: CoreServices.authService?.brokerConnection.mqttClient?.connectionState ?? MQTTSessionManagerState.closed)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func onMqttConnUpdate(notification: NSNotification) {
        if let connState = notification.userInfo?["state"] {
            mqttStatusLabel.text = "MQTT status: " + MQTTMissitoClient.toString(connectionState: connState as! MQTTSessionManagerState)
        }
    }
}
