//
//  MissitoLocation.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class MissitoLocation: Gloss.Decodable, Gloss.Encodable {
    
    let label: String
    let lat: Double
    let lon: Double
    let radius: Double
    
    init(label: String, lat: Double, lon: Double, radius: Double) {
        self.label = label
        self.lat = lat
        self.lon = lon
        self.radius = radius
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard
            let label: String = "label" <~~ json,
            let lat: Double = "lat" <~~ json,
            let lon: Double = "lon" <~~ json,
            let radius: Double = "radius" <~~ json
            else {
                return nil
        }
        
        self.label = label
        self.lat = lat
        self.lon = lon
        self.radius = radius
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "label" ~~> self.label,
            "lat" ~~> self.lat,
            "lon" ~~> self.lon,
            "radius" ~~> self.radius
            ])
    }
    
}
