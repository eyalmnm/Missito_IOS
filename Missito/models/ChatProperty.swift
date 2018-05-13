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
import ObjectMapper
import RealmSwift
import CryptoSwift

//V2.0.0-RC12
final class ChatProperty: Object, MdkObjectType, MdkDynamicObjectType {
    

    //PK
    override static func primaryKey() -> String? {
        return "id"
    }
    
    //Indexes
    override class func indexedProperties() -> [String] { return ["chatId", "value"] }
    
    convenience required init(key: String, value: String, ownerId: String) {
        self.init()
        self.id = (key + ownerId).md5()
        self.key = key
        self.value = value
        self.chatId = ownerId
    }
    
    
    dynamic var id: String?
    dynamic var key: String?
    dynamic var value: String?
    dynamic var chatId: String?
    
}