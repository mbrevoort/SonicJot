//
//  Timer.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/1/24.
//

import Foundation
import CoreFoundation

class Timer {
    let startTime: CFAbsoluteTime

    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() -> CFAbsoluteTime {
        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }
}
