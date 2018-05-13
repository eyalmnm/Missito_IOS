//
//  RealmAudio.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RealmAudio: Object {
    
    dynamic var title: String? = ""
    dynamic var fileName: String = ""
    dynamic var link: String = ""
    dynamic var size: Int64 = 0
    dynamic var secret: String = ""
    
    convenience init(title: String?, fileName: String, link: String, size: Int64, secret: String) {
        self.init()
        self.title = title
        self.fileName = fileName
        self.link = link
        self.size = size
        self.secret = secret
    }
}
