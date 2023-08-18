//
//  AppState.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/10/23.
//

import Foundation
import OpenAI
import KeyboardShortcuts
import Cocoa
import SwiftUI

let jsonEncoder = JSONEncoder()
let jsonDecoder = JSONDecoder()

@MainActor
final class AppState: ObservableObject {
    private static var _instance: AppState = AppState()
    public static func instance() -> AppState {
        return _instance
    }
    
    private let localTranscription = LocalTranscription()
    
    private var lastKeyDownTime: Date?
    private var shouldAutoPasteIfEnabled: Bool = false
    
    @Published var recordingState = stopped
    
    @AppStorage("useOpenAI") var useOpenAI: Bool = true
    @AppStorage("language") var language: String = "en"
    @AppStorage("translateResultToEnglish") var translateResultToEnglish: Bool = false
    @AppStorage("enableAutoPaste") var enableAutoPaste: Bool = false
    @AppStorage("prompt") var prompt: String = "Hello, nice to see you today!"
    
    // history is serialized into serializedHistory and put in AppStorage so that it can survive restarts
    @AppStorage("serializedHistory") private var serializedHistory: String = ""
    var history: History = History(size: 25) {
        didSet {
            do {
                let jsonData = try jsonEncoder.encode(history)
                let updatedSerializedHistory = String(data: jsonData, encoding: String.Encoding.utf8)!
                DispatchQueue.main.async {
                    self.serializedHistory = updatedSerializedHistory
                }
                
            } catch {
                self.showError(error)
            }
        }
    }
    
    
    var apiToken: String = KeychainHelper.getOpenAIToken() {
        didSet {
            KeychainHelper.setOpenAIToken(apiToken)
            self.openAI = OpenAI(apiToken: apiToken)
        }
    }
    lazy public var openAI: OpenAI = OpenAI(apiToken: apiToken)
    let rec = Recording()
    
    init() {
        
        // Register keyboard shortcuts
        KeyboardShortcuts.onKeyDown(for: .toggleRecordMode) { [weak self] in
            self?.keyDown()
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleRecordMode) { [weak self] in
            self?.keyUp()
        }
        
        // Hydrate saved history
        if !self.serializedHistory.isEmpty {
            do {
                let jsonData = self.serializedHistory.data(using: .utf8)!
                let restoredHistory = try jsonDecoder.decode(History.self, from: jsonData)
                self.history.replace(restoredHistory)
            } catch {
                self.showError(error)
            }
        }
        
    }
    
    
    private func keyDown() {
        self.lastKeyDownTime = Date()
        self.shouldAutoPasteIfEnabled = false
        
        if self.recordingState == stopped {
            self.startRecording()
        } else if self.recordingState == recording {
            self.stopRecording()
        }
        
    }
    
    private func keyUp() {
        let sinceLastKeyDown = abs(self.lastKeyDownTime?.timeIntervalSinceNow ?? 0)
        print("sinceLastKeyDown: \(sinceLastKeyDown)")
        let wasHeldDown: Bool = sinceLastKeyDown > 2 //seconds
        if wasHeldDown {
            if self.recordingState == recording {
                self.shouldAutoPasteIfEnabled = true
                self.stopRecording()
            }
        }
    }
    
    
    
    public func startRecording() {
        if useOpenAI && apiToken == "" {
            playErrorSound()
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            return
        }
        
        print("START RECORDING")
        recordingState = recording
        do {
            try rec.record()
            playOKSound()
        } catch {
            self.showError(error)
        }
    }
    
    public func stopRecording() {
        print("STOP RECORDING")
        recordingState = working
        let url = rec.stop()
        playOKSound()
        
        Task {
            await self.transcribe(url: url as URL)
        }
    }
    
    private func transcribe(url: URL) async -> Void  {
        let timer = ParkBenchTimer()
        var text = ""
        do {
            if useOpenAI && translateResultToEnglish {
                text = try await self.translateOpenAI(url: url)
            } else if useOpenAI {
                text = try await self.transcribeOpenAI(url: url)
            } else {
                text = try await self.transcribeLocal(url: url)
            }
            
            print("Transcription result: \(text)")
            self.handleTranscriptionSuccess(text, duration: timer.stop())
            
        } catch {
            self.showError(error)
        }
        
        DispatchQueue.main.async {
            self.recordingState = stopped
        }
    }
    
    
    private func transcribeOpenAI(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try Data(contentsOf: url as URL)
                let query = AudioTranscriptionQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: self.prompt, language: self.language)
                self.openAI.audioTranscriptions(query: query) { result in
                    switch result {
                    case .success(let data):
                        continuation.resume(returning: data.text)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func translateOpenAI(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try Data(contentsOf: url as URL)
                let query = AudioTranslationQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: self.prompt)
                self.openAI.audioTranslations(query: query) { result in
                    switch result {
                    case .success(let data):
                        continuation.resume(returning: data.text)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func transcribeLocal(url: URL) async throws -> String {
        await localTranscription.initModel()
        localTranscription.language = language
        localTranscription.translateToEnglish = translateResultToEnglish
        localTranscription.prompt = "The sentence may be cut off, do not make up words to fill in the rest of the sentence. Don't make up anything that wasn't clearly spoken. Don't include any noises. " + prompt
        return try await withCheckedThrowingContinuation { continuation in
            localTranscription.translateToEnglish = self.translateResultToEnglish
            localTranscription.language = self.language
            localTranscription.transcribe(fileURL: url) { result in
                switch result {
                case .success(let text):
                    continuation.resume(returning: text)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func handleTranscriptionSuccess(_ text: String, duration: Double) {
        logger.info("result: \(text)")
        AppState.setClipboard(text)
        let item = HistoryItem(text)
        item.duration = duration
        self.history.enqueue(item)
        
        if self.enableAutoPaste && self.shouldAutoPasteIfEnabled {
            playDoneAsyncSound()
            paste()
        } else {
            playDoneSound()
        }
    }
    
    public func cancelRecording() {
        print("CANCEL RECORDING")
        recordingState = stopped
        _ = rec.stop()
    }
    
    
    static func setClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    func showError(_ err: any Error) {
        playErrorSound()
        print("error: \(err)")
        logger.error("error: \(err)")
        self.history.enqueue(HistoryItem(body: "\(err)", type: HistoryItemType.error))
    }
    
    // Based on https://github.com/p0deje/Maccy/blob/master/Maccy/Clipboard.swift
    func paste() {
        guard accessibilityAllowed else {
            // Show accessibility window async to allow menu to close.
            DispatchQueue.main.async{
                self.showAccessibilityWindow()
            }
            return
        }
        
        DispatchQueue.main.async {
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
    private var accessibilityAllowed: Bool { AXIsProcessTrustedWithOptions(nil) }
    private let accessibilityURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )
}


