//
//  AttachmentSpec.swift
//  Missito
//
//  Created by Alex Gridnev on 7/3/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

struct AttachmentSpec: Gloss.Decodable {
    
    let uploadURL: String
    let downloadURL: String
    let uploadFields: [String: String]

    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let uploadURL: String = "uploadURL" <~~ json,
            let downloadURL: String = "downloadURL" <~~ json,
            let uploadFields: [String: String] = "uploadFields" <~~ json
            else {
                return nil
        }
        
        self.uploadURL = uploadURL
        self.downloadURL = downloadURL
        self.uploadFields = uploadFields
    }
    
    
}
