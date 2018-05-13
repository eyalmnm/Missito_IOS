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
import RxSwift
import ObjectMapper

@objc(MDKChatMessageService)
final public class ChatMessageService: NSObject, AsyncEventType, EventHandler {

    
    private let brokerConnection: BrokerConnection
    private let messageRepository: MessageRepository
    
    private static var typingUnlocked: Bool = true
    
    init(brokerConnection: BrokerConnection, messageRepository: MessageRepository ) {
    
        self.brokerConnection = brokerConnection
        self.messageRepository = messageRepository
        super.init()
        self.handleIncomingMessages()
        self.handleIncomingMessageStatusRead()
        self.handleIncomingMessageStatusReceived()
        self.handleIncomingPresence()
        self.handleIncomingTyping()
    
    }
    
    @objc
    public func sendMessage(message: Message) {
        
        self.sendMessage(message) { (call) -> Void in }
        
    }
    
    public func sendMessage(message: Message, completion: (call: Call<MessageEvent>) -> Void) {
    
        let date = NSDate()
        message.direction = Direction.OUT
        guard let myId = Mdk.getAccountRepository()?.findOne()?.userId  else { return }
        message.fromUserId = myId
        message.id = NSUUID().UUIDString
        //Persist body
        if let body = message.customBody {
          message.setBody(body)
        }
        message.createdAt = date
        message.sentAt = date
        
        let outgoing = MessageStatus(userId: myId, messageId: message.id!, status: .Outgoing, date: date)
        message.setStatus(outgoing)
        self.emit(MessageEvent.Status(result: outgoing))
        
        //Make sure that message chatId, chat and chat channel exists
        guard let chatId = message.chatId else { return }
        guard let chat = Mdk.getChatRepository()?.findById(chatId) else { return }
        guard let channel = chat.channel else { return }
        
        //Map Message object to MQTT Payload
        let content = Mapper<Message>().toJSON(message)
        
        //Write into the database by emiting events on completion
        self.messageRepository.create(message) {
            
            //Emit event listened by the MQTT publisher
            self.emit(Event(type: EventType.ChatMessage, direction: Direction.OUT, content: content, topic: channel, error: nil))
            //ADD SENT STATUS
            let sent = MessageStatus(userId: myId, messageId: message.id!, status: .Sent, date: date)
            message.setStatus(sent)
            self.emit(MessageEvent.Status(result: sent))
            //Emit event listened by the frontend
            self.emit(MessageEvent.New(result: message))
            //Call the completion callback
            completion(call: Call.onSuccess(MessageEvent.New(result: message)))

        }
    }
    @objc
    public func sendMessagesRead(chatId: String) {
        
        guard let chat = Mdk.getChatRepository()?.findById(chatId) else { return }
        
        guard chat.unreadMessages > 0 else { return }
        
        guard let messages = chat.getMessages() else { return }
        
        for message in messages {
            
            guard let messageId = message.id else { return }
            
            self.sendMessageRead(messageId)
        }
    }
    @objc
    public func sendMessageRead(messageId: String) {
    
        guard let message = Mdk.getMessageRepository()?.findById(messageId) else { return }
        
        guard message.direction == .IN else { return }
        
        guard let myId = Mdk.getAccountRepository()?.findOne()?.userId else { return }
        
        guard let chat = message.getChat() else { return }
        
        //Return if the received status already exist
        if let myStatus = message.getStatuses()?.filter({ $0.userId == myId }).first {
        
            guard myStatus.readDate == nil else { return }
        }
        
        let date = NSDate()
        let status = MessageStatus(userId: myId, messageId: messageId, status: .Read, date: date)
        message.setStatus(status)
        self.emit(MessageEvent.Status(result: status))
        
        chat.setObjectProperties { 
           
            chat.unreadMessages--
        }
        
        let ack = MessageAcknowledge()
        ack.status = .Read
        ack.messageId = message.id
        ack.userId = myId
        
        let content = Mapper<MessageAcknowledge>().toJSON(ack)
        self.emit(Event(type: EventType.MessageStatusRead, direction: Direction.OUT,
            content: content, topic: chat.channel, error: nil))
    }
    
    @objc
    public func sendTypingForChatId(chatId: String) {
        
        guard ChatMessageService.typingUnlocked else { return }
        guard let myId = Mdk.getAccountRepository()?.findOne()?.userId else { return }
        guard let topic = Mdk.getChatRepository()?.findById(chatId)?.channel else { return }
        ChatMessageService.typingUnlocked = false
        NSTimer.scheduledTimerWithTimeInterval(Mdk.SEND_TYPING_INTERVAL, target: self, selector: #selector(ChatMessageService.unlockTyping), userInfo: nil, repeats: false)
        
        let typing = UserTyping()
        typing.chatId = chatId
        typing.userId = myId
        let content = Mapper<UserTyping>().toJSON(typing)
        self.emit(Event(type: EventType.Typing, direction: Direction.OUT,
            content: content, topic: topic, error: nil))
    }
    
    @objc
    private func unlockTyping() { ChatMessageService.typingUnlocked = true }
    
    
    //MARK: Handle Incoming Events
    //TODO: Split handlers in many cases as separated functions
    private func handleIncomingMessages() {
        
        self.handleEvent { event in
            
            guard event.type == EventType.ChatMessage && event.direction == Direction.IN  else { return }
            //Return on Null Event Payload
            guard let content = event.content else { return }
            
            guard let messageId = content["id"] as? String else { return }
            
            guard Mdk.getMessageRepository()?.findById(messageId) == nil else { return }
            
            guard let myId = Mdk.getAccountRepository()?.findOne()?.userId else { return }
            
            //Return on Null message
            guard let message = Mapper<Message>().map(content) else { return }
            
            
            //Setup Message as OUT if it is sent by the same user but from a different device
            if let fromId = message.fromUserId, let date = message.createdAt where fromId == myId && self.messageRepository.findById(messageId) == nil {
                
                message.direction = .OUT
                message.setStatus(.Sent, userId: myId, date: date)
                message.sentAt = date
                
            } else { message.direction = .IN }
            
            if let _ = self.messageRepository.findByIdObjC(messageId) { return }
            
            //Return on message already exist
            if let _ = self.messageRepository.findById(messageId) { return }
            //Return on chatId null
            guard let chatId = message.chatId else { return }
            
            //Store message
            self.messageRepository.create(message)  {
                self.sendMessageReceived(message)
                self.emit(MessageEvent.New(result: message))
            }

            //TODO: Find an elegant solution for handling missing chats
            //If local chat exist increase unreadMessage
            if let chat = Mdk.getChatRepository()?.findById(chatId) where message.direction == .IN  {
    
                //Increase unread messages counter in chat
                
                chat.setObjectProperties({
                    
                    chat.unreadMessages++
                    chat.lastMessageId = messageId
                })
                
                return
            }
            
            Mdk.getChatSyncronizer()?.syncChat(chatId) { (call) in
                
                switch call {
                    
                case .onSuccess(let chat):
                    chat.setObjectProperties({
                        
                        chat.unreadMessages++
                        chat.lastMessageId = messageId
                    })
                    break
                case .onError( _):
                    Mdk.log.error("Failed to get chat with id:\(chatId)")
                    break
                }
            }
        }
    }
    
    private func handleIncomingMessageStatusRead() {
        
        self.handleEvent { event in
            
            guard event.type == EventType.MessageStatusRead && event.direction == Direction.IN  else { return }
            
            //Return on Null Event Payload
            guard let content = event.content else { return }
            //Return on Null message
            guard let ack = Mapper<MessageAcknowledge>().map(content) else { return }
            ack.status = .Read
            
            guard let messageId = ack.messageId else { return }
            
            guard let userId = ack.userId else { return }
            
            guard let myId = Mdk.getAccountRepository()?.findOne()?.userId where userId != myId else { return }
            
            guard let message = Mdk.getMessageRepository()?.findById(messageId) else { return }
            
            guard myId != userId else { return }
            
            let date = NSDate()
            
            let status = MessageStatus(userId: userId, messageId: messageId, status: .Read, date: date)
            
            message.setStatus(status)
            
            self.emit(MessageEvent.Status(result: status))
        }
        
    }
    
    private func handleIncomingMessageStatusReceived() {
        
        self.handleEvent { event in
            
            guard event.type == EventType.MessageStatusReceived && event.direction == Direction.IN  else { return }
            
            //Return on Null Event Payload
            guard let content = event.content else { return }
            //Return on Null message
            guard let ack = Mapper<MessageAcknowledge>().map(content) else { return }
            ack.status = .Received
            
            guard let messageId = ack.messageId else { return }
            
            guard let userId = ack.userId else { return }
            
            guard let myId = Mdk.getAccountRepository()?.findOne()?.userId where userId != myId else { return }
            
            guard let message = Mdk.getMessageRepository()?.findById(messageId) else { return }
            
            let date = NSDate()
            
            let status = MessageStatus(userId: userId, messageId: messageId, status: .Received, date: date)
            
            message.setStatus(status)
            
            self.emit(MessageEvent.Status(result: status))
        }
        
    }
    
    
    
    private func handleIncomingPresence() {
        
        self.handleEvent { event in
            
            guard event.type == EventType.Presence && event.direction == Direction.IN  else { return }
            
            //Return on Null Event Payloady
            guard let content = event.content else { return }
            
            guard let presence = Mapper<UserPresence>().map(content) else { return }
            
           self.emit(UserEvent.Presence(presence: presence))

        }
        
        
    }
    
    private func handleIncomingTyping() {
        
        self.handleEvent { event in
            
            guard event.type == EventType.Typing && event.direction == Direction.IN  else { return }
            
            //Return on Null Event Payloady
            guard let content = event.content else { return }
            
            guard let typing = Mapper<UserTyping>().map(content) else { return }
            
            self.emit(ChatEvent.Typing(typing: typing))
            
        }
        
        
    }
    
    //MARK: Internal use
    internal func sendMessageReceived(message: Message) {
        
        guard message.direction == .IN else { return }
        
        guard let chatId = message.chatId else { return }
        
        guard let chat = Mdk.getChatRepository()?.findById(chatId) else { return }
        
        guard let myId = Mdk.getAccountRepository()?.findOne()?.userId else { return }
        
        //Return if the received status already exist
        if let myStatus = message.getStatuses()?.filter({ $0.userId == myId }).first {
            
            guard myStatus.receiveDate == nil else { return }
        }
        
        guard let messageId  = message.id else { return }
        
        let ack = MessageAcknowledge()
        ack.status = .Received
        ack.messageId = messageId
        ack.userId = Mdk.getAccountRepository()?.findOne()?.userId
        
        let date = NSDate()
        let status = MessageStatus(userId: myId, messageId: messageId, status: .Received, date: date)
        message.setStatus(status)
        self.emit(MessageEvent.Status(result: status))
        
        
        let content = Mapper<MessageAcknowledge>().toJSON(ack)
        self.emit(Event(type: EventType.MessageStatusReceived, direction: Direction.OUT,
            content: content, topic: chat.channel, error: nil))

    }
    
    

}