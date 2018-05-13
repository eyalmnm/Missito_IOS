//
//  InviteRequest.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/27/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import Gloss

class InviteRequest: Gloss.Encodable {

    let lang: String
    let phones: [String]
    
    init(lang: String, phones: [String]) {
        self.lang = lang
        self.phones = phones
    }
    
    func toJSON() -> JSON? {
        return jsonify([
            "lang" ~~> lang,
            "phones" ~~> phones
        ])
    }

}
