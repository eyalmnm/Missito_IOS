//
//  UIHelper.swift
//  Missito
//
//  Created by Alex Gridnev on 8/23/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit

class UIHelper {
    
    
    static func setImageWithConstraints(imageView: UIImageView, image: UIImage?,
                                        widthConstraint: NSLayoutConstraint, heightConstraint: NSLayoutConstraint,
                                        maxWidth: CGFloat, maxHeight: CGFloat) {
        
//        NSLog("MAX %f %f", maxWidth, maxHeight)
//        NSLog("Image original size %f %f", image?.size.width ?? 0, image?.size.height ?? 0)
        imageView.image = image //UIImage.fromBase64(image.thumbnail)
        
        // TODO: what if image is missing (broken base64 data or something)
        let newSize = UIHelper.calcImageSize(image: image, maxWidth: maxWidth, maxHeight: maxHeight)
        
        widthConstraint.constant = newSize.width
        heightConstraint.constant = newSize.height
        
//        NSLog("NEW SIZE %f %f", newSize.width, newSize.height)
        
    }
    
    static func calcImageSize(image: UIImage?, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        let scale = UIScreen.main.scale
        
        let imgSize = image?.size ?? CGSize.init(width: 200.0, height: 200.0)
        
        var newSize: CGSize
        if imgSize.width > maxWidth || imgSize.height > maxHeight {
            newSize = Utils.downscale(size: imgSize, maxWidth: maxWidth, maxHeight: maxHeight)
        } else {
            newSize = Utils.upscale(size: imgSize, maxWidth: maxWidth, maxHeight: maxHeight)
        }
        
        newSize.width = newSize.width / scale
        newSize.height = newSize.height / scale

        return newSize
    }
}
