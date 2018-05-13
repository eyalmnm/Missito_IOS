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

@objc(MDKMessageRepository)
final public class MessageRepository: NSObject, RepositoryType {
    
    /// Asociate RepositoryType generic objects with Realm Object
    public typealias T = Message
    
    @nonobjc
    public var tokens: [String: NotificationToken] = [:]
    
    
    //MARK: Persistent operations
    @objc(create:)
    public func createObjC(message: Message) { self.create(message) }
    
    @objc(update:)
    public func updateObjC(message: Message) { self.update(message) }
    
    @objc(remove:)
    public func deleteObjC(message: Message) { self.delete(message) }
    
    
    
    //MARK: Queries
    /**
     Find Message object by id
     
     - parameter findById: message id
     */
    @objc(findById:)
    public func findByIdObjC(id: String) -> Message? { return self.findById(id) }
    
    @objc
    public func fetchMessagesInChat(chat: Chat) -> [Message]? {
        
        guard let chatId = chat.id else { return nil }
        
        guard let results = self.fetchObjects(Message.self)?.filter(" chatId = %@", chatId) else { return nil }
        
        return Array(results)
    }
    
    @objc
    public func fetchMessagesWithFilterPredicateInChat(chat: Chat, predicate: NSPredicate) -> [Message]? {
        
        guard let chatId = chat.id else { return nil }
        
        guard let results = self.fetchObjects(Message.self)?.filter(" chatId = %@", chatId) else { return nil }
        
        return Array(results.filter(predicate))
    }
    
    @objc
    public func fetchMessagesSortingByPropertyNameInChat(chat: Chat, propertyName: String, ascendig: Bool) -> [Message]? {
        
        guard let chatId = chat.id else { return nil }
        
        guard let results = self.fetchObjects(Message.self)?.filter(" chatId = %@", chatId) else { return nil }
        
        return Array(results.sorted(propertyName, ascending: ascendig))
        
    }
    
    @objc
    public func fetchMessagesWithFilterPredicateInChat(chat: Chat, predicate:NSPredicate, sortByPropertyName propertyName: String, ascending: Bool) -> [Message]? {
        
        guard let chatId = chat.id else { return nil }
        
        guard let results = self.fetchObjects(Message.self)?.filter(" chatId = %@", chatId) else { return nil }
        
        return Array(results.filter(predicate).sorted(propertyName, ascending: ascending))
    }
    
    public func cleanMessagesForDeletedChat(chat: Chat) {
       
        guard let messages = chat.getMessages() else { return }
        
        for message in messages {
            
            GenericRepository<MessageBody>().delete(message.getBody()!)
            GenericRepository<MessageStatus>().delete(message.getStatuses()!)
            self.delete(message)
        }
    }
}