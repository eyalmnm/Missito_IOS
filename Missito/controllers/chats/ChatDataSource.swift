//
//  ChatDataSource.swift
//  Missito
//
//  Created by Alex Gridnev on 8/28/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

protocol ChatDataSourceDelegate: class {
    func openMap(message: ChatMessage)
    func onContactClicked(message: ChatMessage)
    func onImageClicked(message: ChatMessage, indexPath: IndexPath)
    func onVideoClicked(message: ChatMessage, indexPath: IndexPath)
    func getMapSnapshot(_ indexPath: IndexPath, _ location: RealmLocation, _ size: CGSize) -> UIImage?
    func onTextMessageTap(message: ChatMessage)
    func onImageMoreMenu(url: URL)
    func onVideoMoreMenu(url: URL)
    func onLocationMoreMenu(url: URL)
}

class ChatDataSource: NSObject, UITableViewDataSource {
    
    private static let SECTION_DT = 2 * 60 * 60.0
    
    private let typeSuffix: [MessageType:String] = [
        .text : "Txt",
        .image : "Img",
        .contact : "Contact",
        .geo : "Geo",
        .audio : "Audio",
        .video: "Video"
    ]
    
    weak var delegate: ChatDataSourceDelegate?
    private var contact: Contact?
    private var companionPhone: String
    private var loadProgressRepo: LoadProgressRepository
    var sections: [ChatSection] = []
    var currentSenderDeviceId: Int
    
    init(contact: Contact?, delegate: ChatDataSourceDelegate?, loadProgressRepo: LoadProgressRepository) {
        self.contact = contact
        self.loadProgressRepo = loadProgressRepo
        companionPhone = contact?.phone ?? ""
        self.delegate = delegate
        self.currentSenderDeviceId = ContactsStatusManager.deviceIds[contact!.phone] ?? 0
    }
    
    func populateMessages() -> [String] {
        sections = []
        let messages = MissitoRealmDB.fetchChatMessages(companionUid: companionPhone)
        
        var serverIds: [String] = []
        if let firstMessage = messages.first {
            currentSenderDeviceId = firstMessage.senderDeviceId
        }
        
        for realmMsg in messages {
            let chatMessage = ChatMessage.make(from: realmMsg, companion: contact)
            
            if realmMsg.senderDeviceId != currentSenderDeviceId {
                append(message: chatMessage)
            } else {
                append(message: chatMessage)
            }

            if let incomingStatus = realmMsg.incomingStatus, let serverId = realmMsg.serverMsgId {
                switch incomingStatus {
                case .received, .receivedAck, .seen:
                    serverIds.append(serverId)
                default: break
                }
            }
        }
        return serverIds
    }
    
    func append(message: BaseChatMessage) {
        
        var senderDeviceId = currentSenderDeviceId
        if message.direction == .incoming {
            senderDeviceId = (message as! IncomingChatMessage).senderDeviceId
        }
        if sections.isEmpty || senderDeviceId != currentSenderDeviceId {
            currentSenderDeviceId = senderDeviceId
            let section = ChatSection(counterpartyDeviceId: senderDeviceId)
            sections.append(section)
            section.append(message: message)
        } else {
            let section = sections.last!
            if section.shouldIncludeNext(message: message) {
                section.append(message: message)
            } else {
                sections.append(ChatSection(counterpartyDeviceId: currentSenderDeviceId))
                sections.last!.append(message: message)
            }

        }
    }
    
    func appendCheckingForTyping(message: ChatMessage) {
        if let lastMessage = sections.last?.messages.last, lastMessage.type == .typing {
            removeLast()
            append(message: message)
            append(message: lastMessage)
        } else {
            append(message: message)
        }
    }
    
    subscript(index: IndexPath) -> BaseChatMessage {
        return sections[index.section].messages[index.row]
    }
    
    func lastIndexPath() -> IndexPath? {
        let section = sections.count - 1
        guard section >= 0 && !sections[section].messages.isEmpty else {
            return nil
        }
        return IndexPath.init(row: sections[section].messages.count - 1, section: section)
    }
    
    func rowsCount() -> Int {
        var count = 0
        for section in sections {
            count += section.messages.count
        }
        return count
    }
    
    func lastMessageIsForTyping() -> Bool {
        let lastMessage = sections.last?.messages.last
        return lastMessage?.type == .typing
    }
    
    func insert(message: ChatMessage) {
        if lastMessageIsForTyping() {
            sections.last?.removeLast()
        }
        var destSection = sections.count
        var createSection = true
        for (i, section) in sections.enumerated() {
            if section.tooLateFor(message: message), section.counterpartyDeviceId == currentSenderDeviceId {
                destSection = i
                break
            } else if !section.tooEarlyFor(message: message), section.counterpartyDeviceId == currentSenderDeviceId {
                if i < sections.count - 1 {
                    let nextSection = sections[i + 1]
                    // For the sake of simplicity we don't merge sections
                    if !nextSection.isEmpty && nextSection.messages[0].date < message.date {
                        continue
                    }
                }
                destSection = i
                createSection = false
                break
            }
        }
        
        var messageDeviceId = -1
        if message is IncomingChatMessage {
            messageDeviceId = (message as! IncomingChatMessage).senderDeviceId
        }
        var prevSectionDeviceId = -1;
        if destSection > 0 && createSection {
            prevSectionDeviceId = sections[destSection - 1].counterpartyDeviceId
        } else if !sections.isEmpty {
            prevSectionDeviceId = sections[destSection].counterpartyDeviceId
        }
        
        if messageDeviceId == -1 {
            messageDeviceId = prevSectionDeviceId
        }
        
        if createSection {
            let newSection = ChatSection(counterpartyDeviceId: messageDeviceId)
            sections.insert(newSection, at: destSection);
            newSection.insert(message: message);
        } else {
            let targetSection = sections[destSection]
            if (messageDeviceId == prevSectionDeviceId || prevSectionDeviceId == -1) {
                targetSection.insert(message: message)
                if prevSectionDeviceId == -1 {
                    propagateSenderDeviceId(pos: destSection, oldSenderDeviceId: prevSectionDeviceId, newSenderDeviceId: messageDeviceId)
                }
            } else {
                let newSections = targetSection.split(splitMessage: message, secondSectionDeviceId: messageDeviceId)
                sections.remove(at: destSection)
                if !newSections.0.isEmpty {
                    sections.insert(newSections.0, at: destSection)
                    destSection = destSection + 1
                }
                sections.insert(newSections.1, at: destSection)
                propagateSenderDeviceId(pos: destSection + 1, oldSenderDeviceId: prevSectionDeviceId, newSenderDeviceId: messageDeviceId)
            }
        }
    }
    
    private func propagateSenderDeviceId(pos: Int, oldSenderDeviceId: Int, newSenderDeviceId: Int) {
        
        for i in pos..<sections.count {
            let chatSection = sections[i]
            if chatSection.counterpartyDeviceId == oldSenderDeviceId {
                chatSection.counterpartyDeviceId = newSenderDeviceId
            } else {
                break
            }
        }
    }
    
    func findBy(id: String) -> IndexPath? {
        for (sectionInd, section) in sections.enumerated() {
            for (row, message) in section.messages.enumerated() {
                if let message = message as? ChatMessage, message.id == id {
                    return IndexPath(row: row, section: sectionInd)
                }
            }
        }
        return nil
    }
    
    func findBy(serverId: String) -> IndexPath? {
        for (sectionInd, section) in sections.enumerated() {
            for (row, message) in section.messages.enumerated() {
                if let message = message as? ChatMessage, message.serverId == serverId {
                    return IndexPath(row: row, section: sectionInd)
                }
            }
        }
        return nil
    }
    
    func remove(at indexPath: IndexPath) -> BaseChatMessage? {
        let result = sections[indexPath.section].remove(at: indexPath.row)
        if sections[indexPath.section].messages.isEmpty {
            sections.remove(at: indexPath.section)
        }
        return result
    }
    
    func removeLast() {
        sections.last?.removeLast()
        if sections.last?.messages.isEmpty == true {
            sections.removeLast()
        }
    }
    
    func clear() {
        sections.removeAll()
    }
    
    // MARK: - Table view data source
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
    
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return sections[section].messages.count
    }
        
    func getCellId(message: BaseChatMessage) -> String {
        if message.type == .typing  {
            return "typingCell"
        } else {
            let message = message as! ChatMessage
            return (message.direction == .incoming ? "in" : "out") + typeSuffix[message.type]!
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        NSLog("CELL %d %d", indexPath.section, indexPath.row)
        
        let message = sections[indexPath.section].messages[indexPath.row]
        let direction = message.direction
        
        let cellId = getCellId(message: message)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        if message.type == .typing {
            let typingCell = cell as! TypingMessageCell
            typingCell.prepare(contact)
        } else if direction == .incoming {
            let message = message as! IncomingChatMessage
            message.progress = loadProgressRepo.getLoadProgress(messageId: message.id ?? "")
            switch message.type {
            case .contact:
                let incomingContactCell = cell as! IncomingContactChatCell
                incomingContactCell.fill(for: message, onClickAction: { [weak self] in
                    self?.delegate?.onContactClicked(message: message)
                })
            case .image:
                let incomingImageCell = cell as! IncomingImageChatCell
                incomingImageCell.fill(for: message, fullScreenAction: { [weak self] in
                    self?.delegate?.onImageClicked(message: message, indexPath: indexPath)
                    }, onForward: { [weak self] in
                        //TODO: Change this to 'forward option' code
                        self?.delegate?.onImageClicked(message: message, indexPath: indexPath)
                    }, onMoreMenu: { [weak self] url in
                        self?.delegate?.onImageMoreMenu(url: url)
                })
            case .geo:
                let incomingMapCell = cell as! IncomingMapChatCell
                incomingMapCell.fill(message: message, onClick: { [weak self] in
                    self?.delegate?.openMap(message: message)
                    }, createSnapshot: { [weak self] (location, size) -> (UIImage?) in
                        return self?.delegate?.getMapSnapshot(indexPath, location, size)
                    }, onForward: { [weak self] in
                        //TODO: Change this to 'forward option' code
                        self?.delegate?.openMap(message: message)
                    }, onMoreMenu: { [weak self] url in
                        self?.delegate?.onLocationMoreMenu(url: url)
                })
            case .audio:
                let incomingAudioCell = cell as! IncomingAudioChatCell
                incomingAudioCell.fill(for: message)
            case .video:
                let incomingVideoCell = cell as! IncomingVideoChatCell
                incomingVideoCell.fill(for: message, playAction: { [weak self] in
                    self?.delegate?.onVideoClicked(message: message, indexPath: indexPath)
                    }, onForward: { [weak self] in
                        //TODO: Change this to 'forward option' code
                        self?.delegate?.onVideoClicked(message: message, indexPath: indexPath)
                    }, onMoreMenu: { [weak self] url in
                        self?.delegate?.onVideoMoreMenu(url: url)
                })
            default:
                let textCell = cell as! IncomingTextChatCell
                textCell.fill(for: message, onTap: {
                    self.delegate?.onTextMessageTap(message: message)
                })
            }
        } else if direction == .outgoing {
            let message = message as! OutgoingChatMessage
            message.progress = loadProgressRepo.getLoadProgress(messageId: message.id ?? "")
            switch message.type {
            case .contact:
                let outgoingContactCell = cell as! OutgoingContactChatCell
                outgoingContactCell.fill(for: message, onClickAction: { [weak self] in
                    self?.delegate?.onContactClicked(message: message)
                })
            case .image:
                let outgoingImageCell = cell as! OutgoingImageChatCell
                outgoingImageCell.fill(for: message, fullScreenAction: { [weak self] in
                    self?.delegate?.onImageClicked(message: message, indexPath: indexPath)
                    }, onForward: { [weak self] in
                        //TODO: Change this to 'forward option' code
                        self?.delegate?.onImageClicked(message: message, indexPath: indexPath)
                    }, onMoreMenu: { [weak self] url in
                        self?.delegate?.onImageMoreMenu(url: url)
                })
            case .geo:
                let outgoingMapCell = cell as! OutgoingMapChatCell
                outgoingMapCell.fill(message: message, onClick: { [weak self] in
                    self?.delegate?.openMap(message: message)
                    }, createSnapshot: { [weak self] (location, size) -> (UIImage?) in
                        return self?.delegate?.getMapSnapshot(indexPath, location, size)
                    }, onForward: { [weak self] in
                        //TODO: Change this to 'forward option' code
                        self?.delegate?.openMap(message: message)
                    }, onMoreMenu: { [weak self] url in
                        self?.delegate?.onLocationMoreMenu(url: url)
                })
            case .audio:
                let outgoingAudioCell = cell as! OutgoingAudioChatCell
                outgoingAudioCell.fill(for: message, companionPhone: companionPhone)
            case .video:
                let outgoingVideoCell = cell as! OutgoingVideoChatCell
                outgoingVideoCell.fill(for: message, playAction: { [weak self] in
                    self?.delegate?.onVideoClicked(message: message, indexPath: indexPath)
                    }, onForward: { [weak self] in
                        //TODO: Change this to 'forward option' code
                        self?.delegate?.onVideoClicked(message: message, indexPath: indexPath)
                    }, onMoreMenu: { [weak self] url in
                        self?.delegate?.onVideoMoreMenu(url: url)
                })
            default:
                let outCell = cell as! OutgoingTextChatCell
                outCell.fill(for: message, onTap: {
                    self.delegate?.onTextMessageTap(message: message)
                })
            }
        }
        return cell
    }

    class ChatSection {
        
        var messages: [BaseChatMessage] = []
        var counterpartyDeviceId: Int
        
        var isEmpty: Bool {
            return messages.isEmpty
        }
        
        init(counterpartyDeviceId: Int) {
            self.counterpartyDeviceId = counterpartyDeviceId
        }
        
        func append(message: BaseChatMessage) {
            messages.append(message)
            updateInGroupTypeWithNieghbours(index: messages.count - 1)
        }
        
        func remove(at index: Int) -> BaseChatMessage? {
            let result = messages.remove(at: index)
            if index > 0 {
                updateInGroupType(index: index - 1)
            }
            if index < messages.count {
                updateInGroupType(index: index)
            }
            return result
        }
        
        @discardableResult func removeLast() -> BaseChatMessage? {
            if !messages.isEmpty {
                return remove(at: messages.count - 1)
            }
            return nil
        }
        
        func updateInGroupTypeWithNieghbours(index: Int) {
            updateInGroupType(index: index)
            if index > 0 {
                updateInGroupType(index: index - 1)
            }
            if index < messages.count - 1 {
                updateInGroupType(index: index + 1)
            }
        }
        
        private func updateInGroupType(index: Int) {
            
            let message = messages[index]
            let prevMessage: BaseChatMessage? = index > 0 ? messages[index - 1] : nil
            let nextMessage: BaseChatMessage? = index < messages.count - 1 ? messages[index + 1] : nil
            
            let starting = prevMessage == nil || prevMessage!.direction != message.direction || prevMessage!.type == .typing
            let ending = nextMessage == nil || nextMessage!.direction != message.direction || nextMessage!.type == .typing
            
            if starting {
                message.inGroupType = ending ? .single : .first
            } else if ending {
                message.inGroupType = .last
            } else {
                message.inGroupType = .middle
            }
        }
        
        func insert(message: ChatMessage) {
            if messages.isEmpty {
                append(message: message)
                return
            }
            for (i, msg) in messages.enumerated().reversed() {
                if msg.date.isEarlier(than: message.date) {
                    messages.insert(message, at: i + 1)
                    updateInGroupTypeWithNieghbours(index: i + 1)
                    return
                }
            }
            messages.insert(message, at: 0)
            updateInGroupTypeWithNieghbours(index: 0)
        }
        
        func shouldIncludeNext(message: BaseChatMessage) -> Bool {
            guard !messages.isEmpty else {
                return true
            }
            
            var msgSenderDeviceId = -1
            if message is IncomingChatMessage {
                msgSenderDeviceId = (message as! IncomingChatMessage).senderDeviceId
            }
            if counterpartyDeviceId != msgSenderDeviceId && counterpartyDeviceId != -1 &&
                msgSenderDeviceId != -1 {
                return false
            }
            
            let lastMessageDate = messages.last!.date
            let newMessageDate = message.date
            
            if !Calendar.current.isDate(lastMessageDate, inSameDayAs:newMessageDate) {
                return false
            }
            
            return newMessageDate.timeIntervalSince1970 - lastMessageDate.timeIntervalSince1970 < SECTION_DT
        }
        
        func tooLateFor(message: ChatMessage) -> Bool {
            guard !messages.isEmpty else {
                return false
            }
            
            let firstMessageDate = messages.first!.date
            let newMessageDate = message.date

            if !Calendar.current.isDate(firstMessageDate, inSameDayAs:newMessageDate) {
                return false
            }

            return firstMessageDate.timeIntervalSince1970 - newMessageDate.timeIntervalSince1970 >= SECTION_DT
        }
        
        func tooEarlyFor(message: ChatMessage) -> Bool {
            guard !messages.isEmpty else {
                return false
            }
            
            let lastMessageDate = messages.last!.date
            let newMessageDate = message.date
            
            if !Calendar.current.isDate(lastMessageDate, inSameDayAs:newMessageDate) {
                return false
            }
            
            return newMessageDate.timeIntervalSince1970 - lastMessageDate.timeIntervalSince1970 >= SECTION_DT
        }

        
        func formatTitle(contact: Contact, switchedSenderDeviceId: Bool) -> String {
            if let date = messages.first?.date {
                let time = DateFormatter.localizedString(from: date, dateStyle: DateFormatter.Style.none, timeStyle: DateFormatter.Style.short)
                let deviceIdChangeString = switchedSenderDeviceId ? "User switched to a new device" : ""
                
                if date.isToday {
                    return time + deviceIdChangeString
                }
                
                let currentDate = Date()

                if date.month == currentDate.month {
                    return date.format(with: "EEE. dd, ") + time + deviceIdChangeString
                } else if date.year == currentDate.year {
                    return date.format(with: "MMMM EEE. dd, ") + time + deviceIdChangeString
                }
                return date.format(with: "yyyy MMMM EEE. dd, ") + time + deviceIdChangeString
            } else {
                return ""
            }
        }
        
        func split(splitMessage: ChatMessage, secondSectionDeviceId: Int) -> (ChatSection, ChatSection) {
            let splitDate = splitMessage.date;
            let sectionBefore = ChatSection(counterpartyDeviceId: counterpartyDeviceId)
            let sectionAfter = ChatSection(counterpartyDeviceId: secondSectionDeviceId)
            sectionAfter.append(message: splitMessage)
            for message in messages {
                if message.date < splitDate {
                    sectionBefore.append(message: message)
                } else {
                    sectionAfter.append(message: message)
                }
            }
            return (sectionBefore, sectionAfter)
        }

    }
    
}
