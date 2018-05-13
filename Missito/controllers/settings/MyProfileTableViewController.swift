//
//  MyProfileTableViewController.swift
//  Missito
//
//  Created by Jenea Vranceanu on 9/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class MyProfileTableViewController: UITableViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var aboutImageView: UIImageView!
    @IBOutlet weak var helpImageView: UIImageView!
    
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var logoutLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var helpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let sfuiLight17 = UIFont.SFUIDisplayLight(size: 17)
        nameLabel.font = sfuiLight17
        phoneLabel.font = sfuiLight17
        logoutLabel.font = sfuiLight17
        aboutLabel.font = sfuiLight17
        helpLabel.font = sfuiLight17
        
        aboutImageView.tintColor = UIColor.missitoBlue
        helpImageView.tintColor = UIColor.missitoBlue
        
        if let phone = CoreServices.authService?.userId {
            phoneLabel.text = Utils.format(phone: phone)
        } else {
            phoneLabel.text = nil
        }
    }
    
    @IBAction func openEditProfileScreen(_ sender: Any) {
        //open edit profile or something
    }
        
    // Open Name change screen
    func openNameChangeScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "NameInputController") as! NameInputController
        viewController.origin = "settings"
        // Open the Name change screen.
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        nameLabel.text = DefaultsHelper.getUserName()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            openNameChangeScreen()
            break
        case 1:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "privacySettings", sender: self)
            case 1:
                performSegue(withIdentifier: "networkSettings", sender: self)
            case 2:
                logout()
            default:
                break
            }
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 1 {
            return 0.001
        }
    
        return UITableViewAutomaticDimension
    }
    
    private func logout() {
        CoreServices.authService?.logOut()
        
        let authRootNavigation = UIStoryboard(name: "Auth", bundle: nil).instantiateInitialViewController() as? UINavigationController
        UIApplication.shared.windows.first?.rootViewController = authRootNavigation
    }
    
}
