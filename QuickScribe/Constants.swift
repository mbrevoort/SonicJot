//
//  Constants.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/9/23.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecordMode = Self("toggleRecordMode", default: .init(.x, modifiers: [.control, .command]))
}

let recording = "record.circle.fill"
let working = "hourglass.circle"
let stopped = "record.circle"
