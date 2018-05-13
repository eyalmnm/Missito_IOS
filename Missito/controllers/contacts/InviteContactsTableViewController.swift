//
//  InviteContactsTableViewController.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/26/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

class InviteContactsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var selectAll: UIBarButtonItem!
    @IBOutlet weak var inviteViewBottomConstraint: NSLayoutConstraint!
    let contactsDataManager = ContactsDataManager(isMissitoType: false)
    var allSelected = false
    var selectedPhones: Set<String> = Set()
    var currentPhones: [String] = []
    
    private var debouncer: Debouncer?
    private var searchText: String?
    private var progress: MBProgressHUD?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inviteButton.backgroundColor = UIColor.missitoBlue
        searchBar.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        //Hide Keyboard
        tableView.keyboardDismissMode = .onDrag
        
        contactsDataManager.prepareSections()
        tableView.reloadData()
        
        debouncer = Debouncer(delay: 0.8) { [weak self] dispatchedWorkItem in
            guard let selfRef = self else {
                return
            }
            guard !dispatchedWorkItem.isCancelled else {
                return
            }
            
            DispatchQueue.main.sync {
                if selfRef.progress == nil || selfRef.progress?.alpha == 0 {
                    selfRef.progress = Utils.showProgress(message: "", view: selfRef.view);
                }
            }
            
            selfRef.contactsDataManager.filterBy(selfRef.searchText)
            
            if !dispatchedWorkItem.isCancelled {
                DispatchQueue.main.sync {
                    selfRef.progress?.hide(animated: true)
                    selfRef.tableView.reloadData()
                    selfRef.tableView.contentOffset = .zero
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo
        let keyboardFrame = userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        inviteViewBottomConstraint.constant = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide() {
        inviteViewBottomConstraint.constant = 0
    }
    
    @IBAction func sendInvites(_ sender: Any) {
        guard !selectedPhones.isEmpty else {
            return
        }
        
        performSegue(withIdentifier: "showProgress", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        progress?.hide(animated: true)
        if segue.identifier == "showProgress" {
            let vc = (segue.destination as! ProgressViewController)
            vc.progressHandler = SendInvitesProgressHandler(Array(selectedPhones))
        }
    }
    
    func hideKeyboard() {
        searchBar.endEditing(true)
    }
    
    func cancelSearch() {
        debouncer?.stop()
        searchText = nil
        progress?.hide(animated: true)
        contactsDataManager.filterBy(nil)
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
        searchBar.endEditing(true)
        progress?.hide(animated: true)
    }
    
    @IBAction func selectAllButtonClicked(_ sender: Any) {
        allSelected = !allSelected
        selectedPhones.removeAll()
        if allSelected {
            for x in contactsDataManager.originalDatasource {
                for contact in x.contacts {
                    selectedPhones.insert(contact.phone)
                }
            }
        }
        selectAll.title = (allSelected ? "Deselect All" : "Select All")
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return contactsDataManager.datasource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsDataManager.datasource[section].contacts.count
    }
    
    func tableView( _ tableView : UITableView,  titleForHeaderInSection section: Int)-> String? {
        let sectionInst = contactsDataManager.datasource[section]
        return sectionInst.contacts.isEmpty ? nil : sectionInst.type
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return "ABCDEFGHIJKLMNOPQRSTUVWYZ*".map({ String($0) })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AllContactCell
        let contact = contactsDataManager.datasource[indexPath.section].contacts[indexPath.row]
        
        var placeholderString: String = ""
        if let firstNameInitial = contact.firstName.first {
            placeholderString = String(firstNameInitial).uppercased()
        }
        if let secondNameInitial = contact.lastName.first {
            placeholderString = placeholderString + String(secondNameInitial).uppercased()
        }
        
        cell.firstName.text = contact.firstName
        cell.secondName.text = contact.lastName
        cell.phone.text = contact.phone
        cell.isContactSelected.isOn = selectedPhones.contains(contact.phone)
        cell.isContactSelected.myInfo = indexPath
        cell.isContactSelected.removeTarget(nil, action: nil, for: .allEvents)
        cell.isContactSelected.addTarget(self, action: #selector(self.onSwitchClicked(sender:)), for: .valueChanged)
        let name = !contact.lastName.isEmpty ? contact.lastName : contact.firstName
        cell.placeholder.text = name.isEmpty ? "*" : name.substring(to: 1).uppercased()
        // Set the contact image.
        /*if let imageData = contact.imageData {
         cell.profileImageView.image = UIImage(data: imageData)
         }*/
        
        return cell
    }
    
    func onSwitchClicked(sender: UISwitch) {
        if let info = sender.myInfo as? IndexPath {
            let contact = contactsDataManager.datasource[info.section].contacts[info.row]
            if sender.isOn {
                selectedPhones.insert(contact.phone)
            } else {
                selectedPhones.remove(contact.phone)
            }
            
            allSelected = selectedPhones.count == contactsDataManager.originalCount()
            selectAll.title = (allSelected ? "Deselect All" : "Select All")
        }
    }
    
}
