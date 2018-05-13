//
//  RealmLocation.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RealmLocation: Object {
    
    dynamic var label: String = ""
    dynamic var lat: Double = 0
    dynamic var lon: Double = 0
    dynamic var radius: Double = 0

    
    convenience init(label: String, lat: Double, lon: Double, radius: Double) {
        self.init()
        self.label = label
        self.lat = lat
        self.lon = lon
        self.radius = radius
    }
}
