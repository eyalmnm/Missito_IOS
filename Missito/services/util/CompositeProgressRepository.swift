//
//  CompositeProgressRepository.swift
//  Missito
//
//  Created by Alex Gridnev on 4/12/18.
//  Copyright © 2018 Missito GmbH. All rights reserved.
//

import Foundation

class CompositeProgressRepository: LoadProgressRepository {
    
    private var repo1: LoadProgressRepository
    private var repo2: LoadProgressRepository
    
    init(repo1: LoadProgressRepository, repo2: LoadProgressRepository) {
        self.repo1 = repo1
        self.repo2 = repo2
    }

    func getLoadProgress(messageId: String) -> Float? {
        return repo1.getLoadProgress(messageId: messageId) ?? repo2.getLoadProgress(messageId: messageId)
    }

}
