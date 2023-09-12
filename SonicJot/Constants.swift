//
//  Constants.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/9/23.
//

import KeyboardShortcuts
import os
import Cocoa
import Carbon


// Keyboard shortcut registration
extension KeyboardShortcuts.Name {
    static let toggleRecordMode = Self("toggleRecordMode", default: .init(.x, modifiers: [.control, .command]))
    static let toggleInstructionMode  = Self("toggleInstructionMode")
    static let toggleCreativeMode  = Self("toggleCreativeMode")
}

let vKeyCode = UInt16(kVK_ANSI_V)

// Recording statuses
enum RecordingStates: String {
    case recording = "waveform.circle.fill"
    case transcribing = "hourglass.circle"
    case transforming = "function"
    case stopped = "waveform"
    case initializing = "waveform.slash"
}

// Global logger
let logger = Logger(subsystem: "com.brevoort.sonicjot", category: "general")

// Modes
enum Modes: String {
    case transcription = "transcription"
    case instruction = "instruction"
    case creative = "creative"
}


// Sounds

let errorSound = NSSound(named: "error.mp3")
let beepSound = NSSound(named: "ok-beep.mp3")
let pingSound = NSSound(named: "ping.mp3")
let pianoKey1 = NSSound(named: "g-tone.mp3")
let pianoKey2 = NSSound(named: "j-tone.mp3")
let startSound = NSSound(named: "boop1.mp3")
let stopSound = NSSound(named: "boop2.mp3")


func playErrorSound() {
    errorSound?.play()
}

func playDoneSound() {
    beepSound?.play()
}

func playDoneAsyncSound() {
    pingSound?.play()
//    pianoKey2?.play()
}

func playOKSound() {
    NSSound.beep()
//    pianoKey1?.play()
}


func playStartRecordingSound() {
    startSound?.play()
}

func playStopRecordingSound() {
    stopSound?.play()
}
