//
//  NameInputController.swift
//  Missito
//
//  Created by Alex Gridnev on 4/13/18.
//  Copyright © 2018 Missito GmbH. All rights reserved.
//

import UIKit

class NameInputController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    
    // The orig of this view - Currently, only Setting set it and Chat automatically
    var origin: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userName: String? = DefaultsHelper.getUserName()
        if let name = userName {
            nameTextField.text = name
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCheck(_ sender: Any) {
        let name = nameTextField.text ?? ""
        if name.isEmpty {
            _ = Utils.show(message: "Please enter your name", attachedTo: view)
        } else {
            DefaultsHelper.saveUserName(name)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateInitialViewController()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            // If it called from settings tab, use the follow
            if (origin?.lowercased() == "settings") {
                origin = nil
//                appDelegate.window?.rootViewController = viewController
//                (appDelegate.window?.rootViewController as! UITabBarController).selectedIndex = 2
                navigationController?.popViewController(animated: true)
            } else {
                // Default behavior
                appDelegate.window?.rootViewController = viewController
            }
        }
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
