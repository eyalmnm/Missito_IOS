//
//  ImageRealm.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/28/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RealmImage: Object {
    
    dynamic var fileName: String = ""
    dynamic var link: String = ""
    dynamic var size: Int64 = 0
    dynamic var secret: String = ""
    dynamic var thumbnail: String = ""
    
    convenience init(fileName: String, link: String, size: Int64, secret: String, thumbnail: String) {
        self.init()
        self.fileName = fileName
        self.link = link
        self.size = size
        self.secret = secret
        self.thumbnail = thumbnail
    }

}
