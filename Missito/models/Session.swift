

import Foundation
import RealmSwift
import ObjectMapper


//V0.9.0 - object schema version
final class Session: Object, Mappable {
    
    
    /**
     Overriding primaryKey so we can update messages based on the message id
     
     - returns: property name
     */
    override static func primaryKey() -> String? {
        return "id"
    }
    
    
    dynamic var id: String?
    
    
    convenience required init?(map: Map) {
        
        self.init()
        id <- map["id"]

    }
    
    func mapping(map: Map) {
        id <- map["id"]

    }
    
    
}
