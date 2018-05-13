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
import Foundation
import ObjectMapper
import RealmSwift

//V2.0.0-RC8
final public class Member: Object, Mappable, MdkObjectType {

    /**
     Overriding primaryKey so we can update messages based on the message id
     
     - returns: property name
     */
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    
    public override class func indexedProperties() -> [String] { return ["id"] }
    
    public dynamic var id: String?
    public dynamic var userId: String?
    public dynamic var chatId: String?
    public dynamic var lastSeen: NSDate?
    public dynamic var isOnline: Bool = false

    
    
    required convenience public init?(_ map: Map) {
        self.init()
        
    }
    
    required convenience public init(userId: String, chatId: String) {
        self.init()
        self.id = (userId + chatId).md5()
        self.userId = userId
        self.chatId = chatId
    }
    
    required convenience public init(userId: String) {
        self.init()
        self.userId = userId        
    }
    
    public func mapping(map: Map) {
        
        userId <- map["userId"]
        chatId <- map["chatId"]
        
        if let chatID = self.chatId, let userID = self.userId where self.id == nil {
            self.id = (userID + chatID).md5()
        }
    }
    
}