//
//  MissitoAudioMessageSlider.swift
//  Missito
//
//  Created by Jenea Vranceanu on 8/22/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import UIKit

class MissitoAudioMessageSlider: UISlider {

    
    private static let thumbImage = UIImage(named: "slider_thumb")!
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        //set your bounds here
        return CGRect(origin: CGPoint(x: bounds.origin.x, y: frame.origin.y), size: CGSize(width: bounds.width, height: 1))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setThumbImage(MissitoAudioMessageSlider.thumbImage, for: .normal)
        setThumbImage(MissitoAudioMessageSlider.thumbImage, for: .highlighted)
    }
    
}
