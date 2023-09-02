//
//  Clipboard.swift
//  SonicJot
//
//  Created by Mike Brevoort on 9/1/23.
//

import Foundation
import Cocoa

class Clipboard {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    static func paste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        // Press Command + V
        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyVDown?.flags = .maskCommand
        // Release Command + V
        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyVUp?.flags = .maskCommand
        // Post Paste Command
        keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
