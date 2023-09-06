//
//  SettingsModel.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/29/23.
//

import Foundation
import SwiftUI
import OpenAI

class SettingsModel: ObservableObject {
    private static var _instance: SettingsModel = SettingsModel()
    public static func instance() -> SettingsModel {
        return _instance
    }


    private let obf = Obfuscator()
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    
    init() {
        self.openAIToken = self.openAITokenEnc

        if !serializedHistory.isEmpty {
            do {
                let jsonData = self.serializedHistory.data(using: .utf8)!
                let restoredHistory = try jsonDecoder.decode(HistoryModel.self, from: jsonData)
                history.replace(restoredHistory)
            } catch {
                print("ERROR: \(error)")
                // TODO: handle error
                // self.showError(error)
            }
        }
        
    }
    
    @AppStorage("enableOpenAI") var enableOpenAI: Bool = false
    @AppStorage("openAIMode") var openAIMode: Modes = Modes.transcription
    @AppStorage("language") var language: String = "en"
    @AppStorage("translateResultToEnglish") var translateResultToEnglish: Bool = false
    @AppStorage("enableAutoPaste") var enableAutoPaste: Bool = false
    @AppStorage("enableSounds") var enableSounds: Bool = true
    @AppStorage("prompt") var prompt: String = "Hello, nice to see you today!"
    
    // Store an obfuscated version of the openaikey in app storage. This is not "secure"
    // but it will make it a big more challenging to discover. Originally the keychain was
    // used but it caused users to have to enter their admin creditals which was annoying. On
    // Mac, there are user credentials strewn all along the file system in dot files and so on.
    // For now this is acceptable
    @AppStorage("serializedoaik") private var servializedOpenAIToken: String = ""
    
    @Published public var openAIToken: String = "" {
        didSet {
            openAITokenEnc = openAIToken
        }
    }
    private var openAITokenEnc: String {
        set {
            servializedOpenAIToken = obf.stringByObfuscatingString(string: newValue)
            // TODO: watch somewhere so OpenAI client can be updated
        }
        get {
            return obf.revealStringByString(string: servializedOpenAIToken)
        }
    }

    // history is serialized into serializedHistory and put in AppStorage so that it can survive restarts
    // TODO: move into CoreDate or somewhere else, this is short lived
    @AppStorage("serializedHistory") private var serializedHistory: String = ""
    var history: HistoryModel = HistoryModel(size: 25) {
        didSet {
            do {
                let jsonData = try jsonEncoder.encode(history)
                let updatedSerializedHistory = String(data: jsonData, encoding: String.Encoding.utf8)!
                DispatchQueue.main.async {
                    self.serializedHistory = updatedSerializedHistory
                }
                
            } catch {
                print("error: \(error)")
                // TODO: properly handle error, how to bubble out of "didSet" but probably need to refactor the serialization wholesale
                // self.showError(error)
            }
        }
    }
    
    //
    // Accessibility settings
    //
    
    public func showAccessibilityWindow() {
        if accessibilityAlert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
            if let url = accessibilityURL {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private var accessibilityAlert: NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "SonicJot” would like to control this computer using accessibility features."
        alert.informativeText = "Grant access to this application in Security & Privacy preferences, located in System Preferences.\n\nClick + button, select SonicJot and toggle on the checkbox next to it."
        alert.addButton(withTitle: "Deny")
        alert.addButton(withTitle: "Open System Preferences")
        alert.icon = NSImage(named: "NSSecurity")
        return alert
    }
    
    public var accessibilityAllowed: Bool { AXIsProcessTrustedWithOptions(nil) }
    public let accessibilityURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )

}
