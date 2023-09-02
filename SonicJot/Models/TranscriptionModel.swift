//
//  TranscriptionModel.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/30/23.
//

import Foundation
import OpenAI
import KeyboardShortcuts
import Cocoa
import SwiftUI


class TranscriptionModel: ObservableObject {
    @Published var settings: SettingsModel = SettingsModel.instance()
    @ObservedObject private var localTranscription = LocalTranscriptionModel()
    
    @Published var recordingState = RecordingStates.stopped
    private var recordingTimer: ParkBenchTimer?


    public var runningStatus: String {
        get {
            switch recordingState {
            case RecordingStates.initializing:
                return "Initializing..."
            case RecordingStates.stopped:
                return "Ready..."
            case RecordingStates.recording:
                return "Recording..."
            case RecordingStates.working:
                return "Transcribing..."
            }
        }
    }
    
    public func refreshOpenAI(updatedToken: String) {
        self.openAI = OpenAI(apiToken: updatedToken)
    }
    
    lazy public var openAI: OpenAI = OpenAI(apiToken: settings.openAIToken)
    let rec = RecordingModel()
    
    init() {                
        if !settings.enableOpenAI {
            self.recordingState = RecordingStates.initializing
            Task {
                await self.localTranscription.initModel()
                self.recordingState = RecordingStates.stopped
            }
        }
    }
    

    public func startRecording() throws  {
        recordingTimer = ParkBenchTimer()
        if settings.enableOpenAI && settings.openAIToken == "" {
            playErrorSound()
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            return
        }
        
        recordingState = RecordingStates.recording
        try rec.record()
        playOKSound()
    }
    
    public func stopRecording() async {
        let recordingDuration = recordingTimer?.stop() ?? 0
        recordingState = RecordingStates.working
        let url = rec.stop()
        playOKSound()
        
        return await self.transcribe(url: url as URL, recordingDuration: recordingDuration as Double)
    }
    
    private func transcribe(url: URL, recordingDuration: Double) async -> Void  {
        let timer = ParkBenchTimer()
        var text = ""
        do {
            if settings.enableOpenAI && settings.translateResultToEnglish {
                text = try await self.translateOpenAI(url: url)
            } else if settings.enableOpenAI {
                text = try await self.transcribeOpenAI(url: url)
            } else {
                text = try await self.transcribeLocal(url: url)
            }
            
            print("Transcription result: \(text)")
            let item = HistoryItem(text)
            item.duration = timer.stop()
            Clipboard.copy(text)
            settings.history.enqueue(item)
            
            if settings.enableAutoPaste {
                playDoneAsyncSound()
                paste()
            } else {
                playDoneSound()
            }
            //hideMenu()
            
            let components = item.body.components(separatedBy: .whitespacesAndNewlines)
            let words = components.filter { !$0.isEmpty }

            EventTracking.transcription(provider: settings.enableOpenAI ? "OpenAI" : "Local", recordingDuration: recordingDuration, transcriptionDuration: item.duration, numWords: words.count)

        } catch {
            self.showError(error)
        }
        
        DispatchQueue.main.async {
            self.recordingState = RecordingStates.stopped
        }
    }
    
    
    private func transcribeOpenAI(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try Data(contentsOf: url as URL)
                let query = AudioTranscriptionQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: settings.prompt, language: settings.language)
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
                let query = AudioTranslationQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: settings.prompt)
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
        localTranscription.language = settings.language
        localTranscription.translateToEnglish = settings.translateResultToEnglish
        localTranscription.prompt = "The sentence may be cut off, do not make up words to fill in the rest of the sentence. Don't make up anything that wasn't clearly spoken. Don't include any noises. " + settings.prompt
        return try await withCheckedThrowingContinuation { continuation in
            localTranscription.translateToEnglish = settings.translateResultToEnglish
            localTranscription.language = settings.language
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
        
    public func cancelRecording() {
        print("CANCEL RECORDING")
        recordingState = RecordingStates.stopped
        _ = rec.stop()
    }
    
    func showError(_ err: any Error) {
        playErrorSound()
        print("error: \(err)")
        logger.error("error: \(err)")
        settings.history.enqueue(HistoryItem(body: "\(err)", type: HistoryItemType.error))
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
            Clipboard.paste()
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


