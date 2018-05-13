//
//  CustomTabBarController.swift
//  Missito
//
//  Created by George on 23/07/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit
import FontAwesome_swift

class CustomTabBarController: UITabBarController {
    
    
    @IBOutlet weak var bar: UITabBar!
    
    override func viewDidLoad() {
        
        let contactsIcon = UIImage(named: "contacts_tab")
        let contactsIconSelected = UIImage(named: "contacts_tab_selected")
        let contactBarItem = UITabBarItem(title: "Contacts", image: contactsIcon, selectedImage: contactsIconSelected)
        
        let chatsIcon = UIImage(named: "chats_tab")
        let chatsIconSelected = UIImage(named: "chats_tab_selected")
        let chatBarItem = UITabBarItem(title: "Chats", image: chatsIcon, selectedImage: chatsIconSelected)
        
        let settingsIcon = UIImage(named: "settings_tab")
        let settingsIconSelected = UIImage(named: "settings_tab_selected")
        let settingsBarItem = UITabBarItem(title: "Settings", image: settingsIcon, selectedImage: settingsIconSelected)
        
//        contactBarItem.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
//        chatBarItem.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
//        settingsBarItem.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
        
        guard let contacts = viewControllers?[1] else { return }
        guard let chat = viewControllers?[0] else { return }
        guard let settings = viewControllers?[2] else { return }
        
        contacts.tabBarItem = contactBarItem
        chat.tabBarItem = chatBarItem
        settings.tabBarItem = settingsBarItem
        
        if (MissitoRealmDbHelper.getConversationCount() == 0) {
            viewControllers?[0] = contacts
            viewControllers?[1] = chat
        }
    }
    
//    override func viewWillLayoutSubviews() {
//        
//        var tabFrame = self.bar.frame
//        tabFrame.size.height = 60
//        tabFrame.origin.y = self.view.frame.size.height - 60;
//        self.bar.frame = tabFrame;
//        
//    }

}
