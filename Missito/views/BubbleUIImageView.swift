//
//  BubbleImageView.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/29/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class BubbleImageView: UIImageView {
    
    private var corners: UIRectCorner = UIRectCorner.allCorners
    
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners(corners: corners, radius: CGFloat(18))
    }
    
    func setup(_ corners: UIRectCorner) {
        self.corners = corners
        setNeedsLayout()
    }
}
