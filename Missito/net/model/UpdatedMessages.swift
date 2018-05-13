//
//  UpdatedMessages.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/6/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class UpdatedMessages: Gloss.Decodable {

    let updated: [String]
    
    init?(json: JSON) {
        guard let updated: [String] = "updated" <~~ json
            else {
                return nil
        }
        
        self.updated = updated
    }
    
}
