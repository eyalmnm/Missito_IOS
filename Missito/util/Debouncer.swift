//
//  Debouncer.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/21/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation

class Debouncer {
    var callback: ((DispatchWorkItem) -> ())
    var delay: Double
    var task: DispatchWorkItem?
    weak var timer: Timer?
    
    init(delay: Double, callback: @escaping ((DispatchWorkItem) -> ())) {
        self.delay = delay
        self.callback = callback
    }
    
    func call(_ useDelay: Bool = true) {
        stop()
        task = DispatchWorkItem() {
            self.fireNow()
        }
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + (useDelay ? delay : 0), execute: task!);
    }
    
    func stop() {
        if let prevWorkItem = self.task {
            prevWorkItem.cancel()
        }
    }
    
    @objc func fireNow() {
        if let task = task {
            self.callback(task)
        }
    }
}
