//
//  ChatsController.swift
//  Missito
//
//  Created by George Poenaru on 21/07/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class ChatsController: UIViewController, UITableViewDelegate, UITableViewDataSource, Customizable, UISearchBarDelegate, ChatPresenting, Invitable {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var composeButton: UIBarButtonItem?
    var allConversations: [RealmConversation] = []
    var conversations: [RealmConversation] = []
    var debouncer: Debouncer?
    var searchText: String?
    var lastTypingDate: [String: Date] = [:]
    var firstDisplay = true
    private var contactFromNotification: Contact?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()        // remove separators for empty cells
    
        searchBar.delegate = self
        searchBar.barTintColor = UIColor(netHex: 0xEBEBF1)
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = searchBar.barTintColor?.cgColor
        
        
        debouncer = Debouncer(delay: 0.3) { [weak self] dispatchedWorkItem in
            guard !dispatchedWorkItem.isCancelled else {
                return
            }
            
            DispatchQueue.main.async {
                if !dispatchedWorkItem.isCancelled {
                    self?.filterBy(term: self?.searchText)
                }
            }
            
        }
        
        
        allConversations = MissitoRealmDbHelper.fetchConversations()
        filterBy(term: nil)
        composeButton = self.navigationItem.rightBarButtonItem
        

        // Do any additional setup after loading the view.
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
//        tapGesture.cancelsTouchesInView = false
//        tableView.addGestureRecognizer(tapGesture)
        
        tableView.keyboardDismissMode = .onDrag
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatsController.localMessageStatusUpdate(notification:)),
                                               name: AuthService.LOCAL_MESSAGE_STATUS_UPDATE_NOTIF, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatsController.mqttMessageStatusUpdate(notification:)),
                                               name: MQTTMissitoClient.MESSAGE_STATUS_UPDATE_NOTIF, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatsController.onConversationsUpdate(notification:)),
                                               name: MissitoRealmDbHelper.CONVERSATIONS_UPDATE, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatsController.onConversationsUpdate(notification:)),
                                               name: ContactsStatusManager.CONTACT_STATUS_UPDATE_NOTIF, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatsController.onNewMessage(notification:)),
                                               name: MQTTMissitoClient.NEW_MSG_NOTIF, object: nil)
    
        // To update time labels
        reloadDataRepeatedly()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        displayInviteAlertIfNeeded()
    }
    
    func mqttMessageStatusUpdate(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let msgStatus = userInfo[MQTTMissitoClient.MESSAGE_STATUS_KEY] as? MessageStatus,
                let _ = RealmMessage.OutgoingMessageStatus(rawValue: msgStatus.status) {
                updateConversationWith(msgStatus: msgStatus)
            }
        }
    }
            
    func localMessageStatusUpdate(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let localUpdate = userInfo[AuthService.MESSAGE_STATUS_KEY] as? LocalMessageStatus {
                updateConversationWith(localUpdate: localUpdate)
            }
        }
    }
    
    private func updateConversationWith(localUpdate: LocalMessageStatus? = nil, msgStatus: MessageStatus? = nil) {
        let localId = localUpdate?.id
        let serverMsgId = msgStatus?.serverMsgId
        
        for i in 0 ..< conversations.count {
            let conversation = conversations[i]
            if let localId = localId, conversation.lastMessage?.id == localId {
                update(conversation, position: i)
                break
            } else if let serverMsgId = serverMsgId,  conversation.lastMessage?.serverMsgId == serverMsgId {
                update(conversation, position: i)
                break
            }
        }
    }
    
    private func update(_ conversation: RealmConversation, position: Int) {
        if let newConversation = MissitoRealmDbHelper.fetchConversation(with: conversation.id) {
            conversations[position] = newConversation
            tableView.reloadData()
        }
    }
    
    func reloadDataRepeatedly() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
            self.tableView.reloadData()
            self.reloadDataRepeatedly()
        }
    }
    
    func hideKeyboard() {
        searchBar.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !firstDisplay {
            tableView.reloadData()
        }
        firstDisplay = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func onConversationsUpdate(notification: Notification) {
        allConversations = MissitoRealmDbHelper.fetchConversations()
        filterBy(term: searchText)
    }
    
    func onNewMessage(notification: Notification) {
        if let userInfo = notification.userInfo as Dictionary<AnyHashable, Any>? {
            if let msg = userInfo[MQTTMissitoClient.MISSITO_MESSAGE_KEY] as? MissitoMessage {
                
                let isTypingMessage = msg.body.isTyping()
                
                if isTypingMessage {
                    let delta = TimeInterval(msg.incomingMessage.timeSent) + 5.1 - Date().timeIntervalSince1970
                    lastTypingDate[msg.incomingMessage.senderUid] = Date.init(timeIntervalSince1970: TimeInterval(msg.incomingMessage.timeSent))
                    NSLog("DELTA %f", delta)
                    if delta > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delta) {
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    lastTypingDate[msg.incomingMessage.senderUid] = Date.distantPast
                }
                
                tableView.reloadData()
            }
        }
    }
    
    func filterBy(term: String?) {
        NSLog("filter " + (term ?? "none"))
        guard term != nil && !term!.isEmpty else {
            conversations = allConversations
            tableView.reloadData()
            return
        }
        let t = term!.lowercased()
        conversations = allConversations.filter({ (conversation) -> Bool in
            for contact in conversation.counterparts {
                if contact.formatFullName().lowercased().contains(t) {
                    return true
                }
            }
            return conversation.lastMessage?.msg?.lowercased().contains(t) ?? false
        })
        tableView.reloadData()
    }
    
    func cancelSearch() {
        debouncer?.stop()
        searchText = nil
        filterBy(term: nil)
        tableView.reloadData()
    }
    
    func startSearch(_ searchText: String) {
        self.searchText = searchText
        debouncer?.call()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        hideKeyboard()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cancelSearch()
        hideKeyboard()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            startSearch(searchText)
        } else {
            cancelSearch()
        }
    }
    

    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChatsCell
        let conversation = conversations[indexPath.row]
        let contact = conversation.counterparts.first
        cell.fill(for: conversation, lastMessage: getMessageString(contact: contact, conversation: conversation))
        return cell
    }
    
    func getMessageString(contact: RealmMissitoContact?, conversation: RealmConversation) -> NSAttributedString {
        var str = ""
        var image: String? = nil
        var color = UIColor.missitoLightGray
        if let phone = contact?.phone, let date = lastTypingDate[phone], Date().timeIntervalSince1970 - date.timeIntervalSince1970 < 5.0 {
            str = "...Typing"
            color = UIColor.missitoBlue
        } else {
            if let lastMessage = conversation.lastMessage {
                
                let isIncoming = lastMessage.incomingStatus != nil
                
                switch lastMessage.getType() {
                case .audio:
                    image = "mic"
                    str = isIncoming ? "Sent an audio message" : "You've sent an audio message"
                case .contact:
                    image = "contact"
                    str = isIncoming ? "Shared a contact" : "You've shared a contact"
                case .geo:
                    image = "location"
                    str = isIncoming ? "Shared a location" : "You've shared a location"
                case .image:
                    image = "picture"
                    str = isIncoming ? "Shared a photo" : "You've shared a photo"
                case .video:
                    image = "video_icon"
                    str = isIncoming ? "Shared a video" : "You've shared a video"
                case .text:
                    if isIncoming {
                        image = "text"
                    } else {
                        switch lastMessage.outgoingStatus! {
                        case .delivered, .sent:
                            image = "chat_sent"
                        case .seen:
                            image = "chat_received-1"
                        default:
                            break
                        }
                    }
                    str = lastMessage.msg ?? ""
                case .typing:
                    str = "...Typing"         // We won't get here since we get messages from DB, 'typing' feature here requires a separate implementation
                }
            } else {
                str = ""
            }
        }
        
        let result = NSMutableAttributedString(string: "")
        if let image = image {
            result.append(getImageString(imageName: image, size: CGSize.init(width: 15, height: 15)))
        }
        result.append(NSAttributedString(string: str, attributes: [NSForegroundColorAttributeName: color]))
        return result
    }
    
    func getImageString(imageName: String, size: CGSize) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage.coloredImage(image: UIImage(named: imageName), color: UIColor.missitoBlue)
        attachment.bounds = CGRect(x: 0, y: -2, width: size.width, height: size.height)
        let result = NSMutableAttributedString(string: "")
        result.append(NSAttributedString(attachment: attachment))
        result.append(NSMutableAttributedString(string: " "))
        return result
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "openChat" {
            let vc = segue.destination as! ChatController
            if let sender = sender, let indexPath = tableView.indexPath(for: sender as! UITableViewCell),
                let missitoContact = conversations[indexPath.row].counterparts.first {
                vc.contact = Contact.make(from: missitoContact)
            } else if let contact = contactFromNotification {
                vc.contact = contact
            }
        }
    }
    
    func openChat(with contact: Contact, animated: Bool = true) {
        contactFromNotification = contact
        performSegue(withIdentifier: "openChat", sender: nil)
    }

}
