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
import Alamofire
import ObjectMapper

enum Operation {

    case Create(date: NSDate)
    case Update(id: String)
    case Delete(id: String)
    case AddMember(id: String)
    case RemoveMember(id: String)
    
}

@objc(MDKChatService)
final public class ChatService: NSObject, AsyncEventType, EventHandler {
    
    
    private let chatRepository: ChatRepository
    private let apiProvider: ApiProvider
    private let connectionService: ConnectionService
    private let chatMessageService: ChatMessageService
    private var ongoingOperations: [Operation] = []
    
    
    init(chatRepository: ChatRepository, apiProvider: ApiProvider, connectionService: ConnectionService, chatMessageService: ChatMessageService) {
        
        self.chatRepository = chatRepository
        self.apiProvider = apiProvider
        self.connectionService = connectionService
        self.chatMessageService = chatMessageService
         super.init()
        self.handleIncomingChatEvents()        
    }

    //MARK: Create ObjC
    /**
    Create Custom Chat - Completion
    
    - parameter properties:    chat properties
    - parameter singleton:      A singleton chat is a chat that exists exactly once for a list of members. Therefore when creating a singleton chat, the accessibility always has to be locked. If you try to create a singleton chat and a singleton chat for the same list of members already exists, the request will succeed with a status code 200 OK and return the existing chat instead of creating a new one.
    - parameter accessibility: This field can have one of the following values: locked, invite or open and specifies how users can be added to a chat.
    - parameter members:       chat members
    - parameter completion:    completion callback
    */
    @objc(create:completion:)
    public func createObjC(chat: Chat, completion: (Chat?, NSError?)->Void ) {
        
        self.create(chat) { (call: Call<Chat>) in
            
            switch call {
                
            case .onSuccess(let chat): completion(chat, nil); return;
            case .onError(let error as NSError): completion(nil, error); return;
            default: break
                
            }
        }
        
    }
    
    /**
    Create Custom Chat - Completion
    
    - parameter properties:    chat properties
    - parameter singleton:      A singleton chat is a chat that exists exactly once for a list of members. Therefore when creating a singleton chat, the accessibility always has to be locked. If you try to create a singleton chat and a singleton chat for the same list of members already exists, the request will succeed with a status code 200 OK and return the existing chat instead of creating a new one.
    - parameter accessibility: This field can have one of the following values: locked, invite or open and specifies how users can be added to a chat.
    - parameter members:       chat members
    - parameter completion:    completion callback
    */
    @objc(create:singleton:accessibility:members:completion:)
    public func createObjC(properties: [String: String]?, singleton: Bool, accessibility: String, members: [Member], completion: (Chat?, NSError?)->Void ) {
        
        self.create(properties, singleton: singleton, accessibility: accessibility, members: members) { (call: Call<Chat>) in
            
            switch call {
            
            case .onSuccess(let chat): completion(chat, nil); return;
            case .onError(let error as NSError): completion(nil, error); return;
            default: break
            
            }
        }
    }
    
    /**
     Create Locked Chat -> completion
     When a chat is set to locked, chat members cannot be changed after chat creation,
     so no members can be added to or removed from the chat afterwards. An example
     for such a chat could be a chat between 2 members to allow direct messaging.
     
     - parameter properties: chat properties dictionary
     - parameter user:       thirdparty user
     - parameter completion: completion callback
     */
    @objc(createLocked:user:completion:)
    public func createLockedObjC(properties: [String: String]?, member: Member, completion: (Chat?, NSError?)->Void ) {
        
       self.createObjC(properties, singleton: true, accessibility: "locked", members: [member], completion: completion)
    
    }
    /**
     Create Invite Chat -> completion
     Invite chats allow all chat members to add or remove users from the chat. If a user is not member of a chat yet,
     they can not add themselves to the member list. Invite chats can be utilized to realize private chat rooms.
     
     - parameter properties: chat properties dictionary
     - parameter user:       invited users
     - parameter completion: completion callback
     */
    @objc(createInvite:users:completion:)
    public func createInviteObjC(properties: [String: String]?, members: [Member], completion: (Chat?, NSError?)->Void ) {
        
        self.createObjC(properties, singleton: false, accessibility: "invite", members: members, completion: completion)
    }
    
    /**
     Create Open Chat -> completion
     In an open chat every user can join and leave the member list. But a user is not allowed to remove or add other members.
     An example for an open chat is an open world chat in a multiplayer game.
     
     - parameter properties: chat properties dictionary
     - parameter user:       initial users
     - parameter completion: completion callback
     */
    @objc(createOpen:users:completion:)
    public func createOpenObjC(properties: [String: String]?, members: [Member], completion: (Chat?, NSError?)->Void ) {
        
        self.createObjC(properties, singleton: false, accessibility: "open", members: members, completion: completion)
    }
    
    //MARK: Update ObjC
    /**
     Update a chat. Only the properties field can be updated
     
     - parameter chat:       chat
     - parameter completion: completion callback
     */
    @objc(updateChat:completion:)
    public func updateChatObjC(chat: Chat, completion: (Chat?, NSError?) -> Void) {
        
        self.updateChat(chat) { (call) in
            
            switch call {
                
            case .onSuccess(let chat):
                completion(chat, nil)
                break
                
            case .onError(let error as NSError):
                completion(nil, error)
                break
                
            default: break
            }
        }
    }
    
    //MARK: Add Members ObjC
    
    /**
     Add new member to a chat and return the updated chat in database on success.
     
     - parameter chatId:       chat id
     - parameter userId:       user id
     - parameter completion:   completion callback
     */
    @objc(addMemberWithId:chatId:completion:)
    public func addMemberObjC(userId: String, chatId: String, completion: (Member?, NSError?) -> Void) {
        
        self.addMember(chatId, userId: userId) { (call) in
            
            switch call {
                
            case .onSuccess(let member):
                completion(member, nil)
                break
            case .onError(let error as NSError):
                completion(nil, error)
                break
            default: break
                
            }
        }
    }
    
    /**
     Add new members to a chat and return the updated chat in database on success.
     
     - parameter chatId:     chat id
     - parameter userIds:    user id
     - parameter completion: completion callback
     */
    @objc(addMembersWithIds:chatId:completion:)
    public func addMemberObjC(userIds: [String], chatId: String, completion: (Member?, NSError?) -> Void) {
        
        self.addMembers(chatId, userIds: userIds) { (call) in
            
            switch call {
                
            case .onSuccess(let member):
                completion(member, nil)
                break
            case .onError(let error as NSError):
                completion(nil, error)
                break
            default: break
                
            }
        }
    }

    //MARK: Remove Members ObjC
    /**
     Remove member from chat.
     
     - parameter chatId:     chat id
     - parameter userId:     user id
     - parameter completion: completion callback
     */
    @objc(removeMemberWithId:chatId:completion:)
    public func removeMemberObjC(userId: String, chatId: String, completion: (Member?, NSError?) -> Void) {
        
        self.removeMember(chatId, userId: userId) { (call) in
            
            switch call {
                
            case .onSuccess(let member):
                completion(member, nil)
                break
            case .onError(let error as NSError):
                completion(nil, error)
                break
            default: break
                
            }
        }
    }
    
    
    /**
     Remove members from chat
     
     - parameter chatId:     chat id
     - parameter userIds:    array of user ids
     - parameter completion: completion callback
     */
    @objc(removeMembersWithIds:chatId:completion:)
    public func removeMembersObjC(userIds: [String], chatId: String, completion: (Member?, NSError?) -> Void) {
        
        self.removeMembers(chatId, userIds: userIds) { (call) in
            
            switch call {
                
            case .onSuccess(let member):
                completion(member, nil)
                break
            case .onError(let error as NSError):
                completion(nil, error)
                break
            default: break
                
            }
        }
    }

    
    //MARK: Create Swift
    /**
     Create Custom Chat
     
     - parameter properties:    chat properties
     - parameter singleton:      A singleton chat is a chat that exists exactly once for a list of members. Therefore when creating a singleton chat, the accessibility always has to be locked. If you try to create a singleton chat and a singleton chat for the same list of members already exists, the request will succeed with a status code 200 OK and return the existing chat instead of creating a new one.
     - parameter accessibility: This field can have one of the following values: locked, invite or open and specifies how users can be added to a chat.
     - parameter members:       chat members
     - parameter completion:    completion callback
     */
    
    public func create(chat: Chat, completion: (call: Call<Chat>)->Void ) {
        
        _ = self.apiProvider.createChat(chat).subscribe(
            
            //onNext
            onNext: { chat in
                
                //Write created chat into database
                self.chatRepository.create(chat) {
                    //Succesfully return results
                    completion(call: .onSuccess(chat))
                    self.emit(ChatEvent.Created(result: chat))
                }
            },
            
            //onError
            onError: { error in completion(call: .onError(error)) },
            
            //onCompleted              //onDispose
            onCompleted: { () in  }) { ()  in }
    }
    /**
     Create Custom Chat
     
     - parameter chat:    chat
     - parameter completion:    completion callback
     */
    public func create(properties: [String: String]?, singleton: Bool, accessibility: String, members: [Member], completion: (call: Call<Chat>)->Void ) {
        
        guard let myId = Account.myUserId() else { return }
        
        let newChat = Chat()
        
        //Add current account if doesn't exist
        if !(members.contains { $0.userId == myId }) {
            
            let me = Member(userId: myId)
            
            newChat.addMember(me)
        }
        
        newChat.addMembers(members)
    
        guard let properties = properties else {
        
            let error = NSError(domain: "io.mdk", code: 01, userInfo: [:])
            
            completion(call: Call.onError(error))
            
            return
        }
        
        newChat.setProperties(properties)
        newChat.setSingleton(singleton)
        newChat.accessibility = accessibility

        
        self.create(newChat, completion: completion)
    }
    
    /**
     Create Locked Chat -> completion
     When a chat is set to locked, chat members cannot be changed after chat creation, 
     so no members can be added to or removed from the chat afterwards. An example 
     for such a chat could be a chat between 2 members to allow direct messaging.
     
     - parameter properties: chat properties dictionary
     - parameter user:       thirdparty user
     - parameter completion: completion callback
     */
    public func createLocked(properties: [String: String]?, member: Member, completion: (call: Call<Chat>)->Void ) {
        
        self.create(properties, singleton: true, accessibility: "locked", members: [member], completion: completion)
    }
    /**
     Create Invite Chat -> completion
     Invite chats allow all chat members to add or remove users from the chat. If a user is not member of a chat yet, 
     they can not add themselves to the member list. Invite chats can be utilized to realize private chat rooms.
     
     - parameter properties: chat properties dictionary
     - parameter user:       invited users
     - parameter completion: completion callback
     */
    public func createInvite(properties: [String: String]?, members: [Member], completion: (call: Call<Chat>)->Void ) {
        
        self.create(properties, singleton: false, accessibility: "invite", members: members, completion: completion)
    }
    
    /**
     Create Open Chat -> completion
     In an open chat every user can join and leave the member list. But a user is not allowed to remove or add other members. 
     An example for an open chat is an open world chat in a multiplayer game.
     
     - parameter properties: chat properties dictionary
     - parameter user:       initial users
     - parameter completion: completion callback
     */
    public func createOpen(properties: [String: String]?, members: [Member], completion: (call: Call<Chat>)->Void ) {
        
        self.create(properties, singleton: false, accessibility: "open", members: members, completion: completion)
    }
    
    //MARK: Update Swift
    /**
     Update a chat. Only the properties field can be updated
     
     - parameter chat:       chat
     - parameter completion: completion callback
     */
    public func updateChat(chat: Chat, completion: (call: Call<Chat>)->Void ) {
        
        guard let chatId = chat.id else { return }
        
        self.ongoingOperations.append(Operation.Update(id: chatId))
        
        var index = (self.ongoingOperations.count - 1)
        
        _ = self.apiProvider.updateChat(chat).subscribe(
            
            //onNext
            onNext: { chat in
                
                //Write updated chat into database
                self.chatRepository.update(chat) {
                    
                    self.emit(ChatEvent.Updated(result: chat))
                    completion(call: .onSuccess(chat))
                    guard index != -1 else { return }
                    self.ongoingOperations.removeAtIndex(index)
                    index = -1
                }
            },
            
            //onError
            onError: { error in
                completion(call: .onError(error))
                guard index != -1 else { return }
                self.ongoingOperations.removeAtIndex(index)
                index = -1
            },
            
            //onCompleted              //onDispose
        onCompleted: { () in  }) { ()  in }

    }
    
    
    //MARK: Delete Swift
    /**
     This method will delete database chat on succesfully deleted from server
     
     - parameter chat:       chat that need to be deleted
     - parameter completion: callback returning the new database chat results
     */
    public func delete(chat: Chat, completion: (call: Call<Results<Chat>>)->Void) {
        
        guard let chatId = chat.id else { return }
        
        self.ongoingOperations.append(Operation.Delete(id: chatId))
        var index = (self.ongoingOperations.count - 1)
        
        _ = self.apiProvider.deleteChat(chatId).subscribe(
            //onNext
            onNext: { success in

                //Delete it from database
                guard let chat = self.chatRepository.findById(chatId) else {
                    
                    completion(call: .onError(MDKError.errorWithCode(.Generic, failureReason:"Chat doesn't exist in the database")))
                    guard index != -1 else { return }
                    self.ongoingOperations.removeAtIndex(index)
                    index = -1
                    return
                }
                
                GenericRepository<ChatProperty>().delete(chat.getProperties()!)
                GenericRepository<Member>().delete(chat.getMemebers()!)
                Mdk.getMessageRepository()?.cleanMessagesForDeletedChat(chat)
                Mdk.getChatRepository()?.delete(chat) {
                    
                    self.emit(ChatEvent.Deleted(result: chat))
                }
                
                //Error by retrieving new database results after chat succesfully deleted on server
                guard let results = RepositoryProvider.database()?.objects(Chat) else {
                    //Call .onError with an MDK Domain Error
                    completion(call: .onError(MDKError.errorWithCode(.Generic, failureReason:"Failed to retrieve chats from database")))
                    guard index != -1 else { return }
                    self.ongoingOperations.removeAtIndex(index)
                    index = -1
                    return
                }
                
                //Succesfully deleted form server and and returning results.
                completion(call: .onSuccess(results))
                guard index != -1 else { return }
                self.ongoingOperations.removeAtIndex(index)
                index = -1
                
            },
            
            //onError
            onError: { error in
                completion(call: .onError(error))
                guard index != -1 else { return }
                self.ongoingOperations.removeAtIndex(index)
                index = -1
            },
            
            //onCompleted             //onDispose
            onCompleted: { () in }) { ()  in  }
    }
    
    @objc(deleteChat:)
    public func delete(chat: Chat) {
        
        self.delete(chat) { (call) -> Void in
            
        }
    }
    
    
    //MARK: Add Members Swift
    /**
     Add new member to a chat and return the updated chat in database on success.
     
     - parameter chatId:       chat id
     - parameter userId:       user id
     - parameter completion:   completion callback
     */
    public func addMember(chatId: String, userId: String, completion: (call: Call<Member>) -> Void) {
        
        let id = (userId + chatId).md5()
        
        self.ongoingOperations.append(Operation.AddMember(id: id))
        var  index = (self.ongoingOperations.count - 1)
        
        _ = self.apiProvider.addMemberToChat(chatId, userId: userId).subscribe(
            
            //onNext
            onNext: { chat in
                
                chat.addMemberWithUserId(userId) {
                    
                    guard let member = GenericRepository<Member>().findById(id) else { return }
                    self.emit(ChatEvent.MemberAdded(result: member))
                    completion(call: .onSuccess(member))
                    guard index != -1 else { return }
                    self.ongoingOperations.removeAtIndex(index)
                    index = -1
                }
                
            },
            
            //onError
            onError: { error in
                completion(call: .onError(error))
                guard index != -1 else { return }
                self.ongoingOperations.removeAtIndex(index)
                index = -1
            },
            
            //onCompleted              //onDispose
            onCompleted: { () in  }) { ()  in }
    }
    
    /**
     Add new members to a chat and return the updated chat in database on success.
     
     - parameter chatId:     chat id
     - parameter userIds:    user id
     - parameter completion: completion callback
     */
    public func addMembers(chatId: String, userIds: [String], completion: (call: Call<Member>) -> Void ) {
        
        for userId in userIds {
            
            self.addMember(chatId, userId: userId, completion: { (call) in
                //Trigger completion on last object
                
                switch call {
                    
                case .onSuccess(let member):
                    //Trigger completion on last object and error
                    if let last = userIds.last where last == userId {
                        completion(call: Call.onSuccess(member))
                    }
                    break
                case .onError(let error):
                    completion(call: Call.onError(error))
                    return
                }
            })
        }
    }
    
    //MARK: Remove Members Swift
    /**
     Remove member from chat.
     
     - parameter chatId:     chat id
     - parameter userId:     user id
     - parameter completion: completion callback
     */
    public func removeMember(chatId: String, userId: String, completion: (call: Call<Member>) -> Void ) {
        
        let id = (userId + chatId).md5()
        
        self.ongoingOperations.append(Operation.RemoveMember(id: id))
        var index = (self.ongoingOperations.count - 1)
        
        _ = self.apiProvider.removeMemberFromChat(chatId, userId: userId).subscribe(
            
            //onNext
            onNext: { chat in
                
                chat.removeMemberForUserId(userId) {
                 
                    guard let member = GenericRepository<Member>().findById(id) else { return }
                    self.emit(ChatEvent.MemberRemoved(result: member))
                    completion(call: .onSuccess(member))
                    guard index != -1 else { return }
                    self.ongoingOperations.removeAtIndex(index)
                    index = -1
                }
            },
            
            //onError
            onError: { error in
                completion(call: .onError(error))
                guard index != -1 else { return }
                self.ongoingOperations.removeAtIndex(index)
                index = -1
            },
            
            //onCompleted              //onDispose
        onCompleted: { () in }) { ()  in  }
        
    }
    
    /**
     Remove members from chat
     
     - parameter chatId:     chat id
     - parameter userIds:    array of user ids
     - parameter completion: completion callback
     */
    public func removeMembers(chatId: String, userIds: [String], completion: (call: Call<Member>) -> Void ) {
        
        for userId in userIds {
            
            self.removeMember(chatId, userId: userId, completion: { (call) in
                //Trigger completion on last object
                
                switch call {
                    
                case .onSuccess(let member):
                    //Trigger completion on last object and error
                    if let last = userIds.last where last == userId {
                        completion(call: Call.onSuccess(member))
                    }
                    break
                case .onError(let error):
                    completion(call: Call.onError(error))
                    return
                }
            })
        }
    }
    
    //MARK: Without completion
    /**
     Create Locked Chat
     When a chat is set to locked, chat members cannot be changed after chat creation,
     so no members can be added to or removed from the chat afterwards. An example
     for such a chat could be a chat between 2 members to allow direct messaging.
     
     - parameter properties: chat properties dictionary
     - parameter user:       thirdparty user
     - parameter completion: completion callback
     */
    public func createLocked(properties: [String: String]?, member: Member) {
        
        self.create(properties, singleton: true, accessibility: "locked", members: [member], completion: { call in })
    }
    /**
     Create Invite Chat
     Invite chats allow all chat members to add or remove users from the chat. If a user is not member of a chat yet,
     they can not add themselves to the member list. Invite chats can be utilized to realize private chat rooms.
     
     - parameter properties: chat properties dictionary
     - parameter user:       invited users
     - parameter completion: completion callback
     */
    public func createInvite(properties: [String: String]?, members: [Member]) {
        
        self.create(properties, singleton: false, accessibility: "invite", members: members, completion: { call in })
    }
    
    /**
     Create Open Chat
     In an open chat every user can join and leave the member list. But a user is not allowed to remove or add other members.
     An example for an open chat is an open world chat in a multiplayer game.
     
     - parameter properties: chat properties dictionary
     - parameter user:       initial users
     - parameter completion: completion callback
     */
    public func createOpen(properties: [String: String]?, members: [Member]) {
        
        self.create(properties, singleton: false, accessibility: "open", members: members, completion: { call in })
    }
    
    
    /*public func delete(chat: Chat) {
     
     self.delete(chat) { call in }
     
     }*/


    //MARK: Send Messages
    @objc
    public func sendMessage(message: Message) { self.chatMessageService.sendMessage(message) }

    public func sendMessage(message: Message, completion: (call: Call<MessageEvent>) -> Void) {
    
        self.chatMessageService.sendMessage(message, completion: completion)
    }
    @objc
    public func sendMessagesRead(chatId: String) { self.chatMessageService.sendMessagesRead(chatId) }
    @objc
    public func sendMessageRead(messageId: String) { self.chatMessageService.sendMessageRead(messageId) }
    @objc
    public func sendTypingForChatId(chatId: String) { self.chatMessageService.sendTypingForChatId(chatId) }
    
    
    //MARK: Handle Incoming Chat Events
    private func handleIncomingChatEvents() {
        
        //Handle Created
        self.handleEvent { event in
            
            guard event.type == EventType.ChatCreated && event.direction == Direction.IN  else { return }
            //Return on Null Event Payload
            guard let content = event.content else { return }
            
            self.handleIncomingChatEventCreated(content)
        
        }
        
        //Handle Updated
        self.handleEvent { event in
            
            guard event.type == EventType.ChatUpdated && event.direction == Direction.IN  else { return }
            //Return on Null Event Payload
            guard let content = event.content else { return }
            
            self.handleIncomingChatEventUpdated(content)
            
        }
        
        //Handle Removed
        self.handleEvent { event in
            
            guard event.type == EventType.ChatRemoved && event.direction == Direction.IN  else { return }
            //Return on Null Event Payload
            guard let content = event.content else { return }
            
            self.handleIncomingChatEventDeleted(content)
        }
        
        //Handle Member Added
        self.handleEvent { event in
            
            guard event.type == EventType.ChatMemberAdded && event.direction == Direction.IN  else { return }
            //Return on Null Event Payload
            guard let content = event.content else { return }
            
            self.handleIncomingChatEventMemberAdded(content)
        }
        
        //Handle Member Removed
        self.handleEvent { event in
            
            guard event.type == EventType.ChatMemberRemoved && event.direction == Direction.IN  else { return }
            //Return on Null Event Payload
            guard let content = event.content else { return }
            
            self.handleIncomingChatEventMemberRemoved(content)
        }
        
    }
    
    private func handleIncomingChatEventCreated(content: [String: AnyObject]) {
        
        guard let json = content["chat"] else { return }
        
        guard let chat = Mapper<Chat>().map(json) else { return }
        
        guard let chatId = chat.id else { return }
        
        //local chat already exist
        if let _ = self.chatRepository.findById(chatId) {
            return
        }
        
        //Create chat into database
        self.chatRepository.create(chat) {
            self.emit(ChatEvent.Created(result: chat))
        }
    }
    
    private func handleIncomingChatEventUpdated(content: [String: AnyObject]) {
        
        guard let json = content["chat"] else { return }
        
        guard let chat = Mapper<Chat>().map(json) else { return }
        
        guard let chatId = chat.id else { return }
        
        //local chat is missing
        guard let _ = self.chatRepository.findById(chatId) else {
            
            //Create chat into database
            self.chatRepository.create(chat) {
                self.emit(ChatEvent.Created(result: chat))
            }
            
            return
        }
        
        //Prevent double trigger (API + MQTT)
        for operation in self.ongoingOperations {
            
            if case Operation.Update(id: chatId) = operation { return }
            
        }
        
        //Write updated chat into database
        self.chatRepository.update(chat) {
            self.emit(ChatEvent.Updated(result: chat))
        }
        
        
    }
    
    
    private func handleIncomingChatEventDeleted(content: [String: AnyObject]) {
        
        guard let chat = Mapper<Chat>().map(content) else { return }
        
        guard let chatId = chat.id else { return }
        
        guard let localChat = self.chatRepository.findById(chatId) else { return }
        
        //Prevent double trigger (API + MQTT)
        for operation in self.ongoingOperations {
            
            if case Operation.Delete(id: chatId) = operation { return }
            
        }
        
        GenericRepository<ChatProperty>().delete(localChat.getProperties()!)
        GenericRepository<Member>().delete(localChat.getMemebers()!)
        Mdk.getMessageRepository()?.cleanMessagesForDeletedChat(localChat)
        Mdk.getChatRepository()?.delete(localChat) {
            
            self.emit(ChatEvent.Deleted(result: chat))
        }
    }
    
    private func handleIncomingChatEventMemberAdded(content: [String: AnyObject]) {
        
        guard let member = Mapper<Member>().map(content) else { return }
        
        guard let id = member.id where GenericRepository<Member>().findById(id) == nil else { return }
        
        //Prevent double trigger (API + MQTT)
        for operation in self.ongoingOperations {
            
            if case Operation.AddMember(id: id) = operation { return }
            
        }
        
        guard let chatId = member.chatId else { return }
        
        guard let chat = Mdk.getChatRepository()?.findById(chatId) else {
            
            Mdk.getChatSyncronizer()?.syncChat(chatId){ call in
            
                self.emit(ChatEvent.MemberAdded(result: member))
            }
            
            return
        }
        
        chat.addMember(member) {
        
            self.emit(ChatEvent.MemberAdded(result: member))
        }
        
    }
    
    private func handleIncomingChatEventMemberRemoved(content: [String: AnyObject]) {
        
        guard let apiMember = Mapper<Member>().map(content) else { return }
        
        guard let id = apiMember.id, let member = GenericRepository<Member>().findById(id) else { return }
        
        //Prevent double trigger (API + MQTT)
        for operation in self.ongoingOperations {
            
            if case Operation.RemoveMember(id: id) = operation { return }
        }
        
        guard let chatId = member.chatId, let chat = Mdk.getChatRepository()?.findById(chatId) else { return }
        
        guard let userId = member.userId else { return }
        
        guard let myId = Account.myUserId() else { return }
        
        //Delete chat if the current user was removed from chat
        if myId == userId {
            
            GenericRepository<ChatProperty>().delete(chat.getProperties()!)
            GenericRepository<Member>().delete(chat.getMemebers()!)
            Mdk.getMessageRepository()?.cleanMessagesForDeletedChat(chat)
            Mdk.getChatRepository()?.delete(chat) {
                
                self.emit(ChatEvent.Deleted(result: chat))
            }
            
            return
        }
        //Remove Member
        chat.removeMember(member) {
            
            self.emit(ChatEvent.MemberRemoved(result: member))
        }
    }
}
