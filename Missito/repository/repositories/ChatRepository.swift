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

@objc(MDKChatRepository)
final public class ChatRepository: NSObject, RepositoryType {
    
    /// Asociate RepositoryType generic objects with Realm Object
    public typealias T = Chat
    
    @nonobjc
    public var tokens: [String: NotificationToken] = [:]
    
    /**
     Create new Chat into database
     
     - parameter create: chat object
     */
    @objc(create:)
    public func createObjC(chat: Chat) { self.create(chat) }
    
    /**
     Update an exiting chat in database
     
     - parameter update: chat object
     */
    @objc(update:)
    public func updateObjC(chat: Chat) { self.update(chat) }
    
    /**
     Remove an existing chat object from database
     
     - parameter remove: chat object
     */
    @objc(remove:)
    public func deleteObjC(chat: Chat) { self.delete(chat) }
    
    /**
     Find a chat object by id (primary key)
     
     - parameter findById: chat id
     
     - returns: chat object
     */
    @objc(findById:)
    public func findByIdObjC(id: String) -> Chat? { return self.findById(id) }
    
    /**
     Retrieve chat objects from database without any filtering or sorting
     
     - returns: unfiltred and unsorted chat objects
     */
    @objc
    public func fetchChats() -> [Chat]? {
        
        guard let results = self.fetchObjects(Chat.self) else { return nil }
        
        return Array(results)
    }
    
    /**
     Retrieve chat objects from database with filtering predicate but without any sorting
     
     - returns: filtred and unsorted chat objects
     */
    @objc
    public func fetchChatsWithFilterPredicate(predicate: NSPredicate) -> [Chat]? {
        
        guard let results = self.fetchObjects(Chat.self) else { return nil }
        
        return Array(results.filter(predicate))
    }
    /**
     Retrieve chat objects from database sorting by property name but without any filtering
     
     - returns: sorted and unfiltered chat objects
     */
    @objc
    public func fetchChatsSortingByPropertyName(propertyName: String, ascending: Bool) -> [Chat]? {
        
        guard let results = self.fetchObjects(Chat.self) else { return nil }
        
        return Array(results.sorted(propertyName, ascending: ascending))
    }
    /**
     Retrieve chat objects from database with filtering predicate and sorting by property name
     
     - returns: filtred and sorted chat objects
     */
    @objc
    public func fetchChatsWithFilterPredicate(predicate:NSPredicate, sortByPropertyName propertyName: String, ascending: Bool) -> [Chat]? {
        
        guard let results = self.fetchObjects(Chat.self) else { return nil }
    
        return Array(results.filter(predicate).sorted(propertyName, ascending: ascending))
    }
}