//
//  AdaptiveBarsType.swift
//  Missito
//
//  Created by George Poenaru on 21/07/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit



protocol Customizable {
    
    
    
}


extension Customizable where Self: UIViewController {
    
    func staticMissitoNavigationBar() {
        
        guard let currentTitleViewSize = self.navigationItem.titleView?.bounds else { return }
        self.navigationItem.titleView?.frame = CGRect(x: 0, y: 0, width: currentTitleViewSize.width, height: 44)
        
    }
    
    func dynamicMissitoNavigationBar() {
        
        guard let currentTitleViewSize = self.navigationItem.titleView?.bounds else { return }
        self.navigationItem.titleView?.frame = CGRect(x: 0, y: 0, width: currentTitleViewSize.width, height: 44)
        
    }
    
}
