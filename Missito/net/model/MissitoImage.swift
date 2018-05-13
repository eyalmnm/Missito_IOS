//
//  ImageNet.swift
//  Missito
//
//  Created by Jenea Vranceanu on 6/28/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class MissitoImage: Gloss.Decodable, Gloss.Encodable {
    
    let fileName: String
    let link: String
    let size: UInt64
    let secret: String
    let thumbnail: String
    
    init(fileName: String, link: String, size: UInt64, secret: String, thumbnail: String) {
        self.fileName = fileName
        self.link = link
        self.size = size
        self.secret = secret
        self.thumbnail = thumbnail
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard
            let fileName: String = "fileName" <~~ json,
            let link: String = "link" <~~ json,
            let size: UInt64 = "size" <~~ json,
            let secret: String = "secret" <~~ json,
            let thumbnail: String = "thumbnail" <~~ json
            else {
                return nil
        }
        
        self.fileName = fileName
        self.link = link
        self.size = size
        self.secret = secret
        self.thumbnail = thumbnail
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "fileName" ~~> self.fileName,
            "link" ~~> self.link,
            "size" ~~> self.size,
            "secret" ~~> self.secret,
            "thumbnail" ~~> self.thumbnail
            ])
    }

}
