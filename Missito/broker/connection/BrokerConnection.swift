import Foundation
import JWT


final class BrokerConnection {
    
    var connectionOn = false
    
    let port = {
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject], let port = dict["BROKER_PORT"] as? String  {
            
            return Int(port)
        }
        
        return nil
        
        }() as Int?

    
    var mqttClient: MQTTMissitoClient?
    fileprivate let host: String
    
    init(host: String) {
        
        self.host = host

    }
    
    func setClient(signalProto: SignalProto) {
                
        guard let port = self.port else {
            
            NSLog("MQTTClient failed to initialiaze! MQTT Port is missing")
            self.mqttClient = nil;
            return
        
        }
        
        self.mqttClient = MQTTMissitoClient(host: host, port: port, signalProto: signalProto)
    }
    
    //MARK: Connection
    func connect(userId: String, deviceId: Int, token: String) {
        
        guard !connectionOn else {
            return
        }
        
        connectionOn = true

        guard let mqttClient = self.mqttClient else {
        
            NSLog("Failed to connect to broker. Client is not initialized!")
            
            return
        }

        mqttClient.start(userId: userId, deviceId: deviceId, token: token)
    }
    
    func disconnect() {
        guard connectionOn else {
            return
        }
        connectionOn = false
        self.mqttClient?.disconnect()
    }
    
}
