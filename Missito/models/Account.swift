

import Foundation
import RealmSwift
import ObjectMapper


//V0.9.0 - object schema version
final class Account: Object, Mappable {
    
    
    /**
     Overriding primaryKey so we can update messages based on the message id
     
     - returns: property name
     */
    override static func primaryKey() -> String? {
        return "userID"
    }
  
    
    dynamic var userID: String?
    dynamic var clientID: String?
    dynamic var deviceID: String?
    dynamic var ik: Data?
    dynamic var spk: Data?
    dynamic var otpk: Data?
    dynamic var deviceName: String?
    dynamic var deviceModel: String?
    dynamic var accessToken: String?
    dynamic var registerToken: String?
    dynamic var code: String?
    dynamic var verified: Bool = false
    dynamic var createdAt: Date?

    
    convenience required init?(map: Map) {
        
        self.init()
        userID <- map["userID"]
        clientID <- map["clientID"]
        deviceID <- map["deviceID"]
        deviceName <- map["deviceName"]
        deviceModel <- map["deviceModel"]
        accessToken <- map["accessToken"]
    }
    
    func mapping(map: Map) {
        userID <- map["userID"]
        clientID <- map["clientID"]
        deviceName <- map["deviceName"]
        deviceModel <- map["deviceModel"]
        accessToken <- map["accessToken"]
    }
    
    
}
