/*******************************************************************************
 * Copyright 2015 MDK Labs GmbH All rights reserved.
 * Confidential & Proprietary - MDK Labs GmbH ("TLI")
 *
 * The party receiving this software directly from TLI (the "Recipient")
 * may use this software as reasonably necessary solely for the purposes
 * set forth in the agreement between the Recipient and TLI (the
 * "Agreement"). The software may be used in source code form solely by
 * the Recipient's employees (if any) authorized by the Agreement. Unless
 * expressly authorized in the Agreement, the Recipient may not sublicense,
 * assign, transfer or otherwise provide the source code to any third
 * party. MDK Labs GmbH retains all ownership rights in and
 * to the software
 *
 * This notice supersedes any other TLI notices contained within the software
 * except copyright notices indicating different years of publication for
 * different portions of the software. This notice does not supersede the
 * application of any third party copyright notice to that third party's
 * code.
 ******************************************************************************/
//  Created by George Poenaru on 25/11/15.

import Foundation
import RealmSwift
import ObjectMapper

//V2.0.0-RC8
final public class Device: Object, Mappable, MdkObjectType {
    
    // Specify properties to ignore (Realm won't persist these)
    
    //  override static func ignoredProperties() -> [String] {
    //    return []
    //  }
    
    //Conform to RepositoryType
    public typealias T = Device
    //Conform to MdkObjectType
    public typealias P = Device
    
    /**
     Overriding primaryKey so we can update messages based on the message id
     
     - returns: property name
     */
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    dynamic public var id: String?
    dynamic public var key: String?
    dynamic public var value: String?
    
    public func getMessages() -> [Message]? {
        
        return linkingObjects(Message.self, forProperty: "body")
    }
    
    
    required convenience public init?(_ map: Map) {
        self.init()
        
    }
    
    public func mapping(map: Map) {
        
    }
}