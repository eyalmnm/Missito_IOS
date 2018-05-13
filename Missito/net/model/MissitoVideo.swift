//
//  MissitoVideo.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class MissitoVideo: Gloss.Decodable, Gloss.Encodable {
    
    let title: String
    let fileName: String
    let link: String
    let size: UInt64
    let secret: String
    let thumbnail: String
    
    init(title: String, fileName: String, link: String, size: UInt64, secret: String, thumbnail: String) {
        self.title = title
        self.fileName = fileName
        self.link = link
        self.size = size
        self.secret = secret
        self.thumbnail = thumbnail
    }
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard
            let title: String = "title" <~~ json,
            let fileName: String = "fileName" <~~ json,
            let link: String = "link" <~~ json,
            let size: UInt64 = "size" <~~ json,
            let secret: String = "secret" <~~ json,
            let thumbnail: String = "thumbnail" <~~ json
            else {
                return nil
        }
        
        self.title = title
        self.fileName = fileName
        self.link = link
        self.size = size
        self.secret = secret
        self.thumbnail = thumbnail
    }
    
    // MARK: - Serialization
    
    func toJSON() -> JSON? {
        return jsonify([
            "title" ~~> self.title,
            "fileName" ~~> self.fileName,
            "link" ~~> self.link,
            "size" ~~> self.size,
            "secret" ~~> self.secret,
            "thumbnail" ~~> self.thumbnail
            ])
    }
    
}
