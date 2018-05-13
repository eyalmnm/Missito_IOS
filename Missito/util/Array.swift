//
//  Array.swift
//  Missito
//
//  Created by Jenea Vranceanu on 5/30/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(_ object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}
