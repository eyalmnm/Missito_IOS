//
//  BubbleView.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/29/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class BubbleView: UIView {

    var bubbleCornerRadius: CGFloat = 18.0
    private var corners: UIRectCorner = UIRectCorner.allCorners
    
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners(corners: corners, radius: bubbleCornerRadius)
    }
    
    func setup(_ corners: UIRectCorner) {
        self.corners = corners
        setNeedsLayout()
    }
}
