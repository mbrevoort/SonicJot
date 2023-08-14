//
//  Constants.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/9/23.
//

import KeyboardShortcuts
import os
import Cocoa


// Keyboard shortcut registration
extension KeyboardShortcuts.Name {
    static let toggleRecordMode = Self("toggleRecordMode", default: .init(.x, modifiers: [.control, .command]))
}

// Recording statuses
let recording = "record.circle.fill"
let working = "hourglass.circle"
let stopped = "waveform"

// Global logger
let logger = Logger(subsystem: "com.brevoort.quickscribe", category: "general")


// Sounds

func playErrorSound() {
    NSSound(named: "error.mp3")?.play()
}

func playOKSound() {
    NSSound.beep()
}
