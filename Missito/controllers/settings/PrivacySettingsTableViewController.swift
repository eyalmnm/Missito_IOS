//
//  PrivacySettingsTableViewController.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/15/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import MBProgressHUD

class PrivacySettingsTableViewController: UITableViewController {
    
    var progress: MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        updateTableView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progress?.hide(animated: true)
    }
    
    private func updateTableView() {
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) { [weak self] in
            self?.updateTableView()
        }
    }
    
    func toggleStatusVisibility() {
        progress = Utils.showProgress(message: "", view: self.view)
        let showPresenceStatus = !(CoreServices.authService?.profileSettings?.presenceStatus ?? true)
        APIRequests.toggleStatusVisibility(visible: showPresenceStatus) { error in
            if let error = error {
                NSLog(error.localizedDescription)
                self.showErrorDialog()
            } else {
                CoreServices.authService?.profileSettings?.presenceStatus = showPresenceStatus
            }
            
            self.tableView.reloadData()
            self.progress?.hide(animated: true)
        }
    }
    
    func allowSendMessageSeenStatus() {
        progress = Utils.showProgress(message: "", view: self.view)
        let sendMessageStatus = !(CoreServices.authService?.profileSettings?.messageStatus ?? true)
        APIRequests.allowSendMessageSeenStatus(allow: sendMessageStatus) { error in
            if let error = error {
                NSLog(error.localizedDescription)
                self.showErrorDialog()
            } else {
                CoreServices.authService?.profileSettings?.messageStatus = sendMessageStatus
            }
            self.tableView.reloadData()
            self.progress?.hide(animated: true)
        }
    }
    
    func getRemainingStringTime(time: TimeInterval) -> String {
        guard time > 0 else {
            return ""
        }
        if time >= 3600 {
            let hours = Int((time / 3600.0).rounded())
            return String(format: "%d %@", hours, hours >= 2 ? "hours" : "hour")
        } else if time >= 60 {
            let mins = Int((time / 60.0).rounded())
            return String(format: "%d %@", mins, mins >= 2 ? "minutes" : "minute")
        } else {
           return String(format: "%d seconds", Int(time))
        }
    }
    
    func showErrorDialog() {
        Utils.alert(viewController: self, title: "Error", message: "Unable to send privacy settings to server")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PrivacyTableViewCell
        switch indexPath.row {
        case 0:
            cell.title.text = "Show 'Online' Status"
            cell.descriptionLabel.text = "You can change this settings once every 24 hours"
            
            // UISwitch
            let timeDiff = Date().timeIntervalSince1970 - (24 * 60 * 60)
            if DefaultsHelper.getPrivacyOnlineStatusDate() > timeDiff {
                cell.statusSwitch.isEnabled = false
                cell.descriptionLabel.text = String(format: "You will be able to change status in %@", getRemainingStringTime(time: DefaultsHelper.getPrivacyOnlineStatusDate() - timeDiff))
                
            } else {
                cell.statusSwitch.isEnabled = true
            }
            cell.statusSwitch.isOn = CoreServices.authService?.profileSettings?.presenceStatus ?? false
            
            cell.action = { [weak self] in
                self?.toggleStatusVisibility()
                DefaultsHelper.setPrivacyOnlineStatusDate()
                cell.statusSwitch.isEnabled = false
            }
        case 1:
            cell.title.text = "Send 'Seen' Status"
            cell.statusSwitch.isOn = CoreServices.authService?.profileSettings?.messageStatus ?? false
            cell.descriptionLabel.text = "Turning this setting off will hide others 'Seen' status from you"
            cell.action = { [weak self] in
                self?.allowSendMessageSeenStatus()
            }
        default:
            break
        }
        return cell
    }
}
