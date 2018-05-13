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
import Realm
import ObjectMapper

//V2.0.0-RC12 - object schema version
final public class Chat: Object, Mappable, MdkObjectType {

    /**
     Overriding primaryKey so we can update messages based on the message id
     
     - returns: property name
     */
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    /**
     Set indexable chat properties
     
     - returns: array of property names
     */
    override public static func indexedProperties() -> [String] {
        return ["id", "modifiedAt", "unreadMessages"]
    }
    
    override public static func ignoredProperties() -> [String] {
        return ["messages", "members", "customProperties"]
    }
    
    
    public dynamic var id: String?
    public dynamic var channel: String?
    public dynamic var accessibility: String?
    public dynamic var createdAt: NSDate?
    public dynamic var modifiedAt: NSDate?
    public var singleton = RealmOptional<Bool>()
    public dynamic var unreadMessages: Int = 0
    public dynamic var lastMessageId: String?
    internal var members: [Member]?
    internal var customProperties: [String: String]?
    
    
    required convenience public init?(_ map: Map) {
        self.init()
    }
    
    /**
     Mappebale protocol conformation. Do not override.
     
     - parameter map: map
     */
    public final func mapping(map: Map) {
        
        id <- map["id"]
        id <- map["chatId"]
        channel <- map["channel"]
        accessibility <- map["accessibility"]
        createdAt <- (map["createdAt"], self.transformDate())
        modifiedAt <- (map["modifiedAt"], self.transformDate())
        singleton <- (map["singleton"], self.transformRealmOptional() as TransformOf<RealmOptional<Bool>, Bool>)
        unreadMessages <- (map["unreadMessages"], transformUnreadMessages)
        customProperties <- (map["properties"], transformProperties())
        members <- (map["members"], transformMembers())
        lastMessageId <- (map["lastMessage.id"], transformLastMessageId)
    }
    
    /**
     Set object properties for objects that belongs to a database instance. If the object belongs to a database instance, then you can only set up its properties inside a write transaction.
     
     - parameter closure: closure
     */
    public func setObjectProperties(closure: () -> Void) {
        
        self.write(closure)
    }
    
    /**
     Get singkleton property value
     
     - returns: true or false
     */
    public func isSingleton() -> Bool {
        
        guard let value = self.singleton.value else { return false }
    
        return value
    
    }
    
    /**
     Set singleton property
     
     - parameter value: true or false
     */
    public func setSingleton(value: Bool) {
        
        self.write {  self.singleton = RealmOptional(value) }
        
    }
    
    public func addProperty(key: String, value: String) {
        
        guard let chatId = self.id else { return }
        
        let dictionary = [key: value]
        
        guard let property = (self.mapDictionaryToDynamics(dictionary, ownerId: chatId) as [ChatProperty]).first else { return }
        
        GenericRepository<ChatProperty>().update(property)
    }
    
    
    /**
     Set properties for a chat
     
     - parameter dictionary: a dictionary of properties
     */
    public func setProperties(dictionary: [String: String]) {
        
        self.customProperties = dictionary
        
        guard let chatId = self.id else { return }
        
        let objects = self.mapDictionaryToDynamics(dictionary, ownerId: chatId) as [ChatProperty]
        
        GenericRepository<ChatProperty>().update(objects)
    }

    /**
     Get a chat property value by key
     
     - parameter key: property key
     
     - returns: value for key
     */
    public func getPropertyForKey(key: String) -> String? {
        
        guard let chatId = self.id else { return nil }
        
        let id = (key + chatId).md5()
        
        let value = GenericRepository<ChatProperty>().findById(id)?.value
        
        return value
        
    }
    
    /**
     Get all Chat properties
     
     - returns: dictionary of properties
     */
    public func getProperties() -> [String: String]? {
        
        if let properties = self.customProperties { return properties }
        
        guard let chatId = self.id else { return nil }
        
        guard let results = GenericRepository<ChatProperty>().findByProperty("chatId", value: chatId) else { return nil }
        
        let objects = Array(results)
        
        let dictionary = self.mapDynamicsToDictionary(objects)
        
        return dictionary
    
    }
    
    internal func getProperties() -> Results<ChatProperty>? {
        
        guard let chatId = self.id else { return nil }
        
        let results = GenericRepository<ChatProperty>().findByProperty("chatId", value: chatId)
        
        return results
        
    }
    
    /**
     Get filtered and sorted messages in this chat
     
     - parameter predicate:    filter predicate
     - parameter propertyName: sorting by property name
     - parameter ascending:    ascending/descending option
     
     - returns: result messages in chat
     */
    public func getMessagesWithFilterPredicate(predicate: NSPredicate, andStortBy propertyName: String, ascending: Bool) -> [Message]? {
        
        guard let chatId = self.id else { return nil }
        
        guard let results = GenericRepository<Message>().findByProperty("chatId", value: chatId) else { return nil }
        
        return Array(results.filter(predicate).sorted(propertyName, ascending: ascending))
    }
    
    /**
     Get filtered messages in this chat
     
     - parameter predicate: filter predicate
     
     - returns: result messages in this chat
     */
    public func getMessagesWithFilterPredicate(predicate: NSPredicate) -> [Message]? {
        
        
        guard let chatId = self.id else { return nil }
        
        guard let results = GenericRepository<Message>().findByProperty("chatId", value: chatId) else { return nil }
        
        return Array(results.filter(predicate))
     
    }
    
    
    /**
     Get sorted messages in this chat
     
     - parameter propertyName: soreted by property name
     - parameter ascending: ascending or descending
     
     - returns: result messages in this chat
     */
    public func getMessagesSortedBy(propertyName: String, ascending: Bool) -> [Message]? {
        
        guard let chatId = self.id else { return nil }
        
        guard let results = GenericRepository<Message>().findByProperty("chatId", value: chatId) else { return nil }
        
        return Array(results.sorted(propertyName, ascending: ascending))
    }
    
    
    /**
     Get all messages in chat
     
     - returns: all messages in chat
     */
    public func getMessages() -> [Message]? {
        
        guard let chatId = self.id else { return nil }
        
        guard let results = GenericRepository<Message>().findByProperty("chatId", value: chatId) else { return nil }
        
        return Array(results)
        
    }
    
    /**
     Get all messages in chat
     
     - returns: all messages in chat
     */
    public func messages() -> Results<Message>? {
        
        guard let chatId = self.id else { return nil }
        
        guard let results = GenericRepository<Message>().findByProperty("chatId", value: chatId) else { return nil }
        
        return results
        
    }
    
    
    
    /**
     Get chat members
     
     - returns: participants members in this chat
     */
    public func getMemebers() -> [Member]? {
        
        guard let chatId = self.id else { return [] }
        
        guard let results = GenericRepository<Member>().findByProperty("chatId", value: chatId) else { return [] }
        
        return Array(results)
        
    }
    
    /**
     Add member to an existing chat. Do not use it to add users for a new chat.
     
     - parameter members: multiple chat participants
     */
    public func addMember(member: Member, completion: ()-> Void) {
        
        GenericRepository<Member>().update(member) {
        
            completion()
        
        }
    }
    
    
    /**
     Add member to an existing chat. Do not use it to add users for a new chat.
     
     - parameter members: multiple chat participants
     */
    public func addMemberWithUserId(userId: String, completion: ()-> Void) {
        
        //The chat id is missing so it means it is a new chat.
        guard let chatId = self.id else { return }
        
        let member =  Member(userId: userId, chatId: chatId)
        
        self.addMember(member)
    }
    
    /**
     Add multiple members to chat
     
     - parameter members: multiple chat participants
     */
    public func addMembers(members: [Member]) {
        
        if self.members == nil { self.members = members }
        else { self.members?.appendContentsOf(members) }
        
        //The chat id is missing so it means it is a new chat.
        guard let _ = self.id else { return }

        GenericRepository<Member>().update(members)
    }
    
    /**
     Add a single member to the chat
     
     - parameter member: a chat participant
     */
    public func addMember(member: Member) { self.addMembers([member]) }
    
    
    public func removeMember(member: Member, completion: ()-> Void) {
        
        GenericRepository<Member>().delete(member) {
            
            completion()
        }
    
    }
    
    public func removeMemberForUserId(userId: String, completion: ()-> Void) {
        
        guard let chatId = self.id else { return }
        
        let id = (userId + chatId).md5()
        
        guard let member = GenericRepository<Member>().findById(id) else { return }
        
        self.removeMember(member, completion: completion)
        
    }
    
    /**
     Remove all members from chat.
     */
    public func removeAllMembers() {
        
        let members = GenericRepository<Member>().fetchObjects(Member.self)
        
        GenericRepository<Member>().delete(members!)
        
    }
    
    
    public func getLastMessage() -> Message? {
        
        guard let chatId = self.id else { return nil }
        
        return GenericRepository<Message>().findByProperty("chatId", value: chatId)?.sorted("createdAt", ascending: true).last

    }
    
    public func setlastMessage() {
     
        guard let chatId = self.id else { return  }
        
        var lastMessage = GenericRepository<Message>().findByProperty("chatId", value: chatId)?.sorted("createdAt", ascending: true).last
        
        if lastMessage == nil {
            
            Mdk.getMessageSyncronizer()?.sync(self) { Mdk.getChatService()?.emit(ChatEvent.Updated(result: self)) }
        }
        
        if let currentId = lastMessage?.id, let apiId = self.lastMessageId where apiId != currentId {
            
            Mdk.getMessageSyncronizer()?.sync(self) { Mdk.getChatService()?.emit(ChatEvent.Updated(result: self)) }
        }
    }
    
    //MARK: Private
    private func transformProperties() -> TransformOf<[String: String], [String: String]> {
        
        return TransformOf<[String: String], [String: String]>(fromJSON: { (json: [String: String]?) -> [String: String]? in
            
            guard let dictionary = json else { return nil }
        
            self.setProperties(dictionary)
            
            return json
            
        }) { (body: [String: String]?) -> [String: String]? in
            
            return self.getProperties()
        }
    }
    
    /// unreadMessages property map transformation
    private let transformUnreadMessages = TransformOf<Int, Int>(fromJSON: { (value: Int?) -> Int? in
        
        return value
        
        }, toJSON: { (value: Int?) -> Int? in
            //Do not create new Chat with this key because API doesn't know about this property
            return nil
    })
    
    
    
    /// unreadMessages property map transformation
    private let transformLastMessageId = TransformOf<String, String>(fromJSON: { (value: String?) -> String? in
        
        return value
        
        }, toJSON: { (value: String?) -> String? in
            //Do not create new Chat with this key because API doesn't know about this property
            return nil
    })
    
    private func transformMembers() -> TransformOf<[Member], [[String: AnyObject]]> {
        
        return TransformOf<[Member], [[String: AnyObject]]>(fromJSON: { (json: [[String: AnyObject]]?) -> [Member]? in
            
            guard let dictionary = json else { return nil }
            
            guard let members = Mapper<Member>().mapArray(dictionary)?.map({ (member) -> Member in
                
                guard let userId = member.userId, let chatId = self.id else { return member }
                
                member.id = (userId + chatId).md5()
                member.chatId = chatId
                
                return member
            }) else { return nil }
            
            self.addMembers(members)
            
            return members
            
        }) { (objects: [Member]?) -> [[String: AnyObject]]? in
        
            guard let members = (self.id == nil ? objects : self.getMemebers()) else { return nil }

            let json = Mapper().toJSONArray(members).map { (dictionary) -> [String: AnyObject] in
                
                var json = dictionary
                
                json.removeValueForKey("user")
                
                return json
            }
            
            return json
        }
    }
    
}

