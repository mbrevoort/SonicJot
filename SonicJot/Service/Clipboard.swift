//
//  Clipboard.swift
//  SonicJot
//
//  Created by Mike Brevoort on 9/1/23.
//

import ComposableArchitecture
import Cocoa
import Carbon

@DependencyClient
struct ClipboardClient {
    var copy: (String) -> Void
    var paste: () -> Void
    var read: () -> String = { "" }
}

extension DependencyValues {
    var clipboard: ClipboardClient {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue}
    }
}

extension ClipboardClient: DependencyKey {
    static var liveValue: Self {
        
        return Self(
            copy: { text in
                ClipboardService.copy(text)
            },
            paste: {
                ClipboardService.paste()
            },
            read: {
                return ClipboardService.read()
            }
        )
    }
}

fileprivate let vKeyCode = UInt16(kVK_ANSI_V)

class ClipboardService {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    static func read() -> String {
        let pasteboard = NSPasteboard.general
        return pasteboard.pasteboardItems?.first?.string(forType: .string) ?? ""
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

extension ClipboardClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        copy: { _ in },
        paste: { },
        read: { "" }
    )
    
    static let noop = Self(
        copy: { _ in },
        paste: { },
        read: { "" }
    )
}

