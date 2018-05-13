//
//  LoadProgressRepository.swift
//  Missito
//
//  Created by Alex Gridnev on 4/6/18.
//  Copyright © 2018 Missito GmbH. All rights reserved.
//

import Foundation

protocol LoadProgressRepository {
    
    func getLoadProgress(messageId: String) -> Float?
    
}
