//
//  ContactsController.swift
//  Missito
//
//  Created by George Poenaru on 21/07/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class ContactsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, ChatPresenting, Invitable  {

    static let OPEN_CHAT_NOTIFICATION = Notification.Name(rawValue: "open_chat_from_push")
    static let COMPANION_PHONE = "companion_phone"
    
    var userId: String?
    
    private var contacts: [Contact] = []
    private var allContacts: [Contact] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var debouncer: Debouncer?
    private var searchText: String?
    
    private var headerView: UserInfoView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = Bundle.main.loadNibNamed("UserInfoView", owner: nil, options: nil)![0] as? UserInfoView
        headerView?.nameLabel.text = DefaultsHelper.getUserName()
        if let phone = CoreServices.authService?.userId {
            headerView?.phoneLabel.text = phone
        } else {
            headerView?.phoneLabel = nil
        }
        let avatar = UIImage(named: "avatar_placeholder")
        headerView?.avatarImageView.image = avatar
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView()        // remove separators for empty cells
            
        NotificationCenter.default.addObserver(self, selector: #selector(ContactsController.onStatusUpdate(notification:)),
                                               name: ContactsStatusManager.CONTACT_STATUS_UPDATE_NOTIF, object: nil)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(ContactsController.unreadCounterUpdate(notification:)),
//                                               name: MissitoRealmDbHelper.UNREAD_COUNTER_UPDATE, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ContactsController.openChatNotification(notification:)),
                                               name: ContactsController.OPEN_CHAT_NOTIFICATION, object: nil)

        //Setup navigation bar
//        shyNavBarManager.scrollView = tableView
//        shyNavBarManager.extensionView = searchBar
        searchBar.delegate = self
        searchBar.barTintColor = UIColor(netHex: 0xEBEBF1)
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = searchBar.barTintColor?.cgColor
        
        // Do any additional setup after loading the view.
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        //Hide Keyboard

//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
//        tapGesture.cancelsTouchesInView = false
//        tableView.addGestureRecognizer(tapGesture)
        
        tableView.keyboardDismissMode = .onDrag
        
        // ANIMATION
//        let contentInset = tableView.contentInset;
//        loadingInset.top += tableView.frame.size.height;
//        
//        CGPoint contentOffset = scrollView.contentOffset;
//        
//        [UIView animateWithDuration:0.2 animations:^
//            {
//            scrollView.contentInset = loadingInset;
//            scrollView.contentOffset = contentOffset;
//            }];
        
        
  
        debouncer = Debouncer(delay: 0.3) { [weak self] dispatchedWorkItem in
            guard !dispatchedWorkItem.isCancelled else {
                return
            }
            
            DispatchQueue.main.async {
                self?.filterContactsBy(term: self?.searchText)
                
                if !dispatchedWorkItem.isCancelled {
                    self?.tableView.reloadData()
                }
            }
            
        }
        
        if ContactsManager.contactsReady {
            populateContacts()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(ContactsController.onContactsReady(notification:)),
                                                   name: ContactsManager.CONTACTS_READY_NOTIF, object: nil)
        }
        
        // to update 'last seen' time
        reloadDataRepeatedly()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.topItem?.title = "Contacts"
        headerView?.nameLabel.text = DefaultsHelper.getUserName()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayInviteAlertIfNeeded()
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
    
    func cancelSearch() {
        debouncer?.stop()
        searchText = nil
        filterContactsBy(term: nil)
        tableView.reloadData()
    }
    
    func startSearch(_ searchText: String) {
        self.searchText = searchText
        debouncer?.call()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            startSearch(searchText)
            hideKeyboard()
        }
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        debouncer?.stop()
        if searchBar != nil {
            searchBar.endEditing(true)
        }
    }
    
    let compareContacts: (Contact, Contact) -> Bool = { (ca, cb) -> Bool in
        let caIsNew = ca.isNew()
        let cbIsNew = cb.isNew()
        
        if caIsNew != cbIsNew {
            return caIsNew
        }
        
        let caStatus = ContactsStatusManager.getStatus(phone: ca.phone)
        let cbStatus = ContactsStatusManager.getStatus(phone: cb.phone)
        
        if caStatus.isBlocked != cbStatus.isBlocked {
            return cbStatus.isBlocked
        }
        
        if caStatus.isOnline != cbStatus.isOnline {
            return caStatus.isOnline
        }
        
        if ca.lastName != cb.lastName {
            return ca.lastName < cb.lastName
        }
        
        return ca.firstName < cb.firstName
        
    }
    
    func populateContacts() {
        if ContactsManager.accessAllowed {
            NSLog("start sort")
            if let missitoContacts = MissitoRealmDbHelper.getMissitoContacts() {
                allContacts = missitoContacts.map({ (missitoContact) -> Contact in
                    return Contact.make(from: missitoContact)
                })
            } else {
                allContacts = []
            }
            contacts = allContacts.sorted(by: compareContacts)
            NSLog("stop sort")
            tableView.reloadData()
        } else {
            Utils.alert(viewController: self, title: "No permission to read contacts", message: "Could not read contacts")
        }
    }
    
    func filterContactsBy(term: String?) {
        NSLog("filterContactsBy " + (term ?? "none"))
        guard term != nil && !term!.isEmpty else {
            contacts = allContacts.sorted(by: compareContacts)
            tableView.reloadData()
            return
        }
        contacts = allContacts.filter({ (contact) -> Bool in
            Utils.cleanPhone(contact.phone).contains(Utils.cleanPhone(term!)) ||
                contact.formatFullName().lowercased().contains(term!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        }).sorted(by: compareContacts)
        tableView.reloadData()
    }
    
    func onStatusUpdate(notification: Notification) {
        if ContactsManager.contactsReady && ContactsManager.accessAllowed {
            populateContacts()
            filterContactsBy(term: self.searchText)
        }
//        if ContactsManager.contactsReady && !ContactsManager.contacts.isEmpty && missitoContactsDataManager.phoneContact.isEmpty {
//            populateContacts()
//        }
//        if let userInfo = notification.userInfo {
//            if let contactsUpdate = userInfo[ContactsStatusManager.DATA_KEY] as? ContactsStatusUpdate {
//                missitoContactsDataManager.updateContactsStatus(online: contactsUpdate.online, offline: contactsUpdate.offline,
//                                          blocked: contactsUpdate.blocked, unblocked: [])
//            }
//            if let blockedPhone = userInfo[ContactsStatusManager.BLOCKED_PHONE_KEY] as? String {
//                missitoContactsDataManager.updateContactsStatus(online: [], offline: [], blocked: [blockedPhone], unblocked: [])
//            }
//            if let unblockedPhone = userInfo[ContactsStatusManager.UNBLOCKED_PHONE_KEY] as? String {
//                missitoContactsDataManager.updateContactsStatus(online: [], offline: [], blocked: [], unblocked: [unblockedPhone])
//            }
//            tableView.reloadData()
//        }
    }
    
    @IBAction func showInviteScreen(_ sender: Any) {
        performSegue(withIdentifier: "showNonMissitoContacts", sender: nil)
    }
    
//    func unreadCounterUpdate(notification: Notification) {
//        if let userInfo = notification.userInfo, let missitoContact = userInfo[MissitoRealmDbHelper.MISSITO_CONTACT_KEY] as? RealmMissitoContact {
//            missitoContactsDataManager.unreadCounterUpdate(missitoContact)
//            tableView.reloadData()
//        }
//    }
    
    func openChatNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let phone = userInfo[ContactsController.COMPANION_PHONE] as? String,
                let contact = ContactsManager.contactsByPhone[phone] {
                openChat(with: contact)
            }
        }
    }
    
    func openChat(with contact: Contact, animated: Bool = true) {
        let storyboard = UIStoryboard(name: "Chats", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "chatController") as! ChatController
        controller.contact = contact
        navigationController?.pushViewController(controller, animated: animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func onContactsReady(notification: Notification) {
        populateContacts()
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Contacts"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view:UIView, forSection: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = UIColor.missitoLightGray
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MissitoContactCell
        let contact = contacts[indexPath.row]
        cell.updateFor(contact: contact)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let contact = contacts[indexPath.row]
        openChat(with: contact)
    }
}
