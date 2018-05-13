//
//  ContactInfoViewController.swift
//  Missito
//
//  Created by Alex Gridnev on 9/18/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class ContactInfoViewController: UITableViewController {

    @IBOutlet weak var avatarView: MissitoContactAvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastSeenLabel: UILabel!
    @IBOutlet weak var blockLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var mutedSwitch: UISwitch!

    var contact: Contact?
    var formattedPhone: String?
    var onHistoryCleared: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let phone = contact!.phone
        let status = ContactsStatusManager.getStatus(phone: phone)
        formattedPhone = Utils.format(phone: phone)

        avatarView.fill(contact!)
        nameLabel.text = contact?.formatFullName()
        lastSeenLabel.text = status.getStatusLabel()
        phoneLabel.text = formattedPhone!
        
        blockLabel.text = status.isBlocked ? "Unblock user" : "Block user"
        mutedSwitch.isOn = status.isMuted && !status.isBlocked
        mutedSwitch.isEnabled = !status.isBlocked
    }
    
    @IBAction func onChatClick(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onCallClick(_ sender: Any) {
        Utils.call(phone: formattedPhone!, viewController: self)
    }
    @IBAction func onMuteStateChange(_ sender: Any) {
        let muted = (sender as! UISwitch).isOn
        NSLog("Mute: %@", muted ? "ON" : "OFF")
        
        let phone = contact!.phone
        
        APIRequests.updateContactsStatus(block: [], normal: muted ? [] : [phone], muted: muted ? [phone] : []) { error in
            if let error = error {
                NSLog(error.localizedDescription )
                self.mutedSwitch.isOn = !muted
            } else {
                if muted {
                    ContactsStatusManager.muteUser(phone: phone)
                } else {
                    ContactsStatusManager.unmuteUser(phone: phone)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.section == 1 && indexPath.row == 1) {
            clearHistory()
        } else if (indexPath.section == 1 && indexPath.row == 2) {
            revertBlockStatus()
        }
    }
    
    func clearHistory() {
        let alertController = UIAlertController(title: "Clean history", message:nil, preferredStyle: .actionSheet)
        
        let actions = [
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil),
            UIAlertAction(title: "for the last hour", style: .destructive, handler: { action in
                self.confirmClearHistory(timePeriod: 3600)
            }),
            UIAlertAction(title: "for last 24 hours", style: .destructive, handler: { action in
                self.confirmClearHistory(timePeriod: 24 * 3600)
            }),
            UIAlertAction(title: "from the beginning", style: .destructive, handler: { action in
                self.confirmClearHistory(timePeriod: 0)
            })
        ]
        
        for action in actions {
            alertController.addAction(action)
        }
        
        self.present(alertController, animated: true)

    }
    
    func confirmClearHistory(timePeriod: TimeInterval) {
        Utils.alert(viewController: self,
                    title: "Clean history",
                    message: "You will not be able to restore chat history. Are you sure you want to clear history?",
                    actions: [
                        UIAlertAction(title: "Cancel", style: .cancel, handler: nil),
                        UIAlertAction(title: "Clean history", style: .destructive, handler: { action in
                            Utils.clearHistory(for: self.contact!.phone, timePeriod: timePeriod)
                            self.onHistoryCleared?()
                        })
            ])
    }
    
    func revertBlockStatus() {
        ContactsStatusManager.revertUserBlockStatus(phone: contact!.phone) { (error, blocked) in
            if error == nil {
                self.mutedSwitch.isOn = false
                self.mutedSwitch.isEnabled = !blocked!
                self.blockLabel.text = blocked! ? "Unblock user" : "Block user"
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
