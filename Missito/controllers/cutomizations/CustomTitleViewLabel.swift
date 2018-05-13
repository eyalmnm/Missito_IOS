//
//  CustomTitleViewLabel.swift
//  Missito
//
//  Created by George Poenaru on 22/07/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit

class CustomTitleViewLabel: UILabel {

    let topInset = CGFloat(28.0), bottomInset = CGFloat(12.0), leftInset = CGFloat(12.0), rightInset = CGFloat(12.0)
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override var intrinsicContentSize : CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
    
}
