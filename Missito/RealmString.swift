//
//  RealmString.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/10/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import RealmSwift

class RealmString: Object {
    dynamic var stringValue = ""
    
    static func make(from: String) -> RealmString {
        let realmStr = RealmString()
        realmStr.stringValue = from
        return realmStr
    }
    
    static func joined(_ list: List<RealmString>, with separator: String) -> String {
        let seq = sequence(state: list.makeIterator()) { (iterator) -> String? in
            let str = iterator.next()?.stringValue
            return str
        }
        return seq.joined(separator: separator)
    }
}
