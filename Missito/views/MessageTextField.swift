//
//  MessageTextField.swift
//  Missito
//
//  Created by George Poenaru on 23/08/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class MessageTextField: UITextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //Setup message text field
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        layer.cornerRadius = 17
        autoresizingMask = [.flexibleWidth, . flexibleHeight]
        rightViewMode = .always
    }
    
    //placeholder position
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 0)
    }
    
    //text position
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let customBounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width - 16, height: bounds.size.height))
        return customBounds.insetBy(dx: 10, dy: 0)
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let rightBounds = CGRect(x: bounds.size.width - 32, y: 2, width: 30, height: 30)
        return rightBounds
    }
    
    func setCustomRightView(_ view: UIView) {
        view.alpha = 0
        rightView = view
        UIView.animate(withDuration: 0.1, animations: {
            view.alpha = 1
            self.layoutIfNeeded()
        })
    }
    
    func setWidth(_ newWidth: CGFloat) {
        frame.size = CGSize(width: newWidth, height: 34)
    }
}
