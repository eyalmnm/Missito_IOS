//
//  OTPCheckResponse.swift
//  Missito
//
//  Created by Alex Gridnev on 5/1/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

final class OTPCheckResponse: NSObject, Gloss.Decodable {
    
    let token: String
    
    // MARK: - Deserialization
    
    init?(json: JSON) {
        guard let token: String = "token" <~~ json
            else {
                return nil
        }
        
        self.token = token
    }
    
}
