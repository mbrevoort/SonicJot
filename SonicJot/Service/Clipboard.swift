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
    var put: (String) -> Void
    var paste: () -> Void
    var read: () -> String = { "" }
    var copy: () async -> String = { "" }
    var copyAndRestore: () async -> String = { "" }
    var pasteAndRestore: (String) async -> Void
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
            put: { text in
                ClipboardService.put(text)
            },
            paste: {
                ClipboardService.paste()
            },
            read: {
                return ClipboardService.read()
            },
            copy: {
                return await ClipboardService.copyFromSystem()
            },
            copyAndRestore: {
                return await ClipboardService.copyAndRestore()
            },
            pasteAndRestore: { value in
                await ClipboardService.pasteAndRestore(value)
            }
        )
    }
}

fileprivate let vKeyCode = UInt16(kVK_ANSI_V)
fileprivate let cKeyCode = UInt16(kVK_ANSI_C)

class ClipboardService {
    static func put(_ text: String) {
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
    
    static func copyFromSystem() async -> String {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyCDown = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: true)
        keyCDown?.flags = .maskCommand
        let keyCUp = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: false)
        keyCUp?.flags = .maskCommand
        // Post Copy Command
        keyCDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyCUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Delay before reading from clipboard to overcome race condition
        try! await Task.sleep(nanoseconds: UInt64(0.35 * Double(NSEC_PER_SEC)))
        
        return self.read()
    }
    
    static func copyAndRestore() async -> String {
        let existing = self.savePasteboardContents()
        let newValue = await self.copyFromSystem()
        
        // restore existing value
        self.restorePasteboardContents(with: existing)

        return newValue
    }
    
    static func pasteAndRestore(_ value: String) async {
        print("Paste and restore \(value)")
        let existing = self.savePasteboardContents()
        
        self.put(value)
        self.paste()
        
        // there's a race condition with issue paste and setting a new value of the pasteboard
        try! await Task.sleep(nanoseconds: UInt64(0.35 * Double(NSEC_PER_SEC)))

        // restore existing value
        self.restorePasteboardContents(with: existing)
    }
    
    struct PasteboardItemData {
        var data: Data
        var type: NSPasteboard.PasteboardType
    }

    // Save the current pasteboard contents which must be copied by value
    static func savePasteboardContents() -> [PasteboardItemData] {
        let pasteboard = NSPasteboard.general
        var savedItems: [PasteboardItemData] = []

        if let items = pasteboard.pasteboardItems {
            for item in items {
                for type in item.types {
                    if let data = item.data(forType: type) {
                        savedItems.append(PasteboardItemData(data: data, type: type))
                    }
                }
            }
        }
        
        return savedItems
    }

    // Restore the pasteboard contents from the saved data and types
    static func restorePasteboardContents(with savedItems: [PasteboardItemData]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        for item in savedItems {
            pasteboard.setData(item.data, forType: item.type)
        }
    }
    
}

extension ClipboardClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        put: { _ in },
        paste: { },
        read: { "" },
        copy: { "" },
        copyAndRestore: { "" },
        pasteAndRestore: {_ in}
    )
    
    static let noop = Self(
        put: { _ in },
        paste: { },
        read: { "" },
        copy: { "" },
        copyAndRestore: { "" },
        pasteAndRestore: {_ in}
    )
}

