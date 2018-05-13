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


//V2.0.0-RC12
final public class Message: Object, Mappable, MdkObjectType {
    
    
    //Persistent properties
    public dynamic var id: String?
    public dynamic var chatId: String?
    public dynamic var fromUserId: String?
    public dynamic var direction: Direction = .NULL
    public dynamic var sentAt: NSDate?
    public dynamic var createdAt: NSDate?
    public dynamic var type: String?
    internal var statuses: [MessageStatus]?
    internal var customBody: [String: String]?

    
    required convenience public init?(_ map: Map) {
        self.init()
    }
    
    /**
     Overriding primaryKey so we can update messages based on the message id
     
     - returns: property name
     */
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    // Specify properties to ignore (Realm won't persist these)
    
    override public static func ignoredProperties() -> [String] {
        return ["statuses", "customBody"]
    }
    
    
    public func mapping(map: Map) {
        
        guard let myId = Account.myUserId() else { return }
        
        id <- map["id"]
        chatId <- map["chatId"]
        fromUserId <- map["from.userId"]
        direction = (fromUserId == myId ? .OUT : .IN)
        type <- map["type"]
        createdAt <- (map["createdAt"], self.transformDate())
        sentAt <- (map["sentAt"], self.transformDate())
        statuses <- (map["status"], self.transformStatus())
        customBody <- (map["body"], self.transformBody())
    }
    
    
    /**
     Set object properties for objects that belongs to a database instance.
     If the object belongs to a database instance, then you can only set up its properties inside a write transaction.
     
     - parameter closure: closure
     */
    public func setObjectProperties(closure: () -> Void) {
        
        self.write(closure)
    }
    
    /**
     Setup message body with a dictionary
     
     - parameter dictionary: dictionary
     */

    public func setBody(dictionary: [String: String]) {

        self.customBody = dictionary
        
        guard let messageId = self.id else { return }
        
        let objects = self.mapDictionaryToDynamics(dictionary, ownerId: messageId) as [MessageBody]
       
        GenericRepository<MessageBody>().update(objects)
    }
    
    public func getBodyValueForKey(key: String) -> String? {
        
        guard let messageId = self.id else { return nil }
        
        let id = (key + messageId).md5()
        
        let value = GenericRepository<MessageBody>().findById(id)?.value
        
        return value
    }
    
    public func getBody() -> [String: String]? {
        
        if let body = self.customBody {
            
            return body
        }
        
        guard let messageId = self.id else { return nil }
        
        guard let results = GenericRepository<MessageBody>().findByProperty("messageId", value: messageId) else { return nil }
        
        let objects = Array(results)
        
        let dictionary = self.mapDynamicsToDictionary(objects)
        
        return dictionary
    }
    
    
    internal func getBody() -> Results<MessageBody>? {
        
        guard let messageId = self.id else { return nil }
        
        guard let results = GenericRepository<MessageBody>().findByProperty("messageId", value: messageId) else { return nil }
        
        return results
    }
    
    public func getChat() -> Chat? {
        
        guard let chatId = self.chatId else { return nil }
        
        return Mdk.getChatRepository()?.findById(chatId)
    }
    
    public func getStatuses() -> [MessageStatus]? {
        
        guard let messageId = self.id else { return nil }
        
        guard let results = GenericRepository<MessageStatus>().findByProperty("messageId", value: messageId) else { return nil }
        
        return Array(results)
    }
    
    public func getStatusForUserId(userId: String) -> MessageStatus? {
        
        guard let messageId = self.id else { return nil }
        
        guard let results = GenericRepository<MessageStatus>().findByProperty("messageId", value: messageId) else { return nil }
        
        guard let status = results.filter("userId = %@", userId).first else { return nil }
        
        return status
    }
    
    internal func setStatus(status: Status, userId: String, date: NSDate) {
        
        guard let messageId = self.id else { return }
        
        let status = MessageStatus(userId: userId, messageId: messageId, status: status, date: date)
        
        self.setStatus(status)
        
    }
    
    
    internal func setStatus(status: MessageStatus) {
        
        guard let statusId = status.id else { return }
        
        guard let localStatus = GenericRepository<MessageStatus>().findById(statusId) else {
            
            GenericRepository<MessageStatus>().create(status) {
                
                Mdk.getChatMessageService()?.emit(MessageEvent.Status(result: status))
                
            }
            
            return
        }
        
        
        GenericRepository<MessageStatus>().update(status) {
            
            Mdk.getChatMessageService()?.emit(MessageEvent.Status(result: status))
        }
    }
    
    //TODO: Database crash on inserting completion callback in a loop so multiple statuses copletions will not fire status events
    internal func setMultipleStatuses(statuses: [MessageStatus]) {
        
        guard let lastStatusId = statuses.last?.id else { return }
        
        guard let lastStatus = statuses.last else { return }
        
        for status in statuses {
            
            guard let statusId = status.id else { continue }
            
            guard GenericRepository<MessageStatus>().findById(statusId) != nil else {
                
                GenericRepository<MessageStatus>().create(status)
                
                continue
            }
            
            GenericRepository<MessageStatus>().update(status)
        }
        
    }
    
    
    
    
    //MARK: Private
    private func transformStatus() -> TransformOf<[MessageStatus], [[String: AnyObject]]> {
        
        return TransformOf<[MessageStatus], [[String: AnyObject]]>(fromJSON: { (json: [[String: AnyObject]]?) -> [MessageStatus]? in
            
            guard let objects = Mapper<MessageStatus>().mapArray(json) else { return nil }
            
            guard let _ = Account.myUserId() else { return nil }
            
            for object in objects {
                
                guard let userId = object.userId, let messageId = self.id, let fromId = self.fromUserId else { return nil }
                
                object.id = (messageId + userId).md5()
                object.messageId = messageId
                
                if userId == fromId  {
                    
                    object.sentDate = self.createdAt
                }
            }
            
            self.setMultipleStatuses(objects)
            
            return objects
            
        }) { (status: [MessageStatus]?) -> [[String: AnyObject]]? in
            
            return nil
        }
    }
    
    
    private func transformBody() -> TransformOf<[String: String], [String: String]> {
        
        return TransformOf<[String: String], [String: String]>(fromJSON: { (json: [String: String]?) -> [String: String]? in

            guard let dictionary = json else { return nil }
            
            self.setBody(dictionary)
            
            return json
            
        }) { (body: [String: String]?) -> [String: String]? in
            
            return self.getBody()
        }
    }
    
    
    
}
