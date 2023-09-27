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

    
    public func refreshOpenAI(updatedToken: String) {
        self.openAI = OpenAI(apiToken: updatedToken)
    }
    
    lazy public var openAI: OpenAI = OpenAI(apiToken: settings.openAIToken)
    let rec = RecordingModel()
    let recQueue = RecordingQueue()
    
    init() {                
        self.recordingState = RecordingStates.initializing
        Task {
            do {
                try await self.localTranscription.initModel()
                self.recordingState = RecordingStates.stopped
            } catch {
                showError(error)
            }
        }
    }
    

    public func startRecording() throws  {
        recordingTimer = ParkBenchTimer()
        if settings.enableOpenAI && settings.openAIToken == "" {
            if settings.enableSounds {
                playErrorSound()
            }
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            return
        }
        
        recordingState = RecordingStates.recording
        try rec.record()
        recQueue.startRecording()
        if settings.enableSounds {
            playStartRecordingSound()
        }
        
        // Shim this in here now but move out if we keep it
        Task {
            await processBufferedAudio()
        }
    }
    
    private func processBufferedAudio() async {
        let data = self.recQueue.clearIncremental()
        if data.count == 0 && !self.recQueue.isRunning {
            print("Done")
            return
        }
        
        if data.count > 0 {
            let text = try! await self.transcribeLocal(data: data)
            print("Text: \(text)")
        }
        
        try! await Task.sleep(nanoseconds: 2000000000)  // Two seconds
        await self.processBufferedAudio()
    }
    
    public func stopRecording(mode: Modes) async {
        let recordingDuration = recordingTimer?.stop() ?? 0
        recordingState = RecordingStates.transcribing
        recQueue.stopRecording()
        
        let url = rec.stop()
        if settings.enableSounds {
            playStopRecordingSound()
        } 
        
        return await self.transcribe(mode: mode, url: url as URL, recordingDuration: recordingDuration as Double)
    }
    
    private func transcribe(mode: Modes, url: URL, recordingDuration: Double) async -> Void  {
        let timer = ParkBenchTimer()
        var text = ""
        do {

            // Always transcribe locally
//            text = try await self.transcribeLocal(url: url)
            
            //let data = await self.recQueue.clear()
            //text = try await self.transcribeLocal(data: data)

            // This is how we did it previously when you could select OpenAI as an option,
            // leaving this commented out for a little bit longer in case we need to fall back.
            /*
            if settings.enableOpenAI && settings.translateResultToEnglish {
                text = try await self.translateOpenAI(url: url)
            } else if settings.enableOpenAI {
                text = try await self.transcribeOpenAI(url: url)
            } else {
                text = try await self.transcribeLocal(url: url)
            }
            */
            
            print("Transcription result strm: \(text)")
            let text2 = try await self.transcribeLocal(url: url)
            print("Transcription result file: \(text2)")
            
            if mode == .instruction {
                recordingState = RecordingStates.transforming
                let chatPrompts: [Chat] = [Chat(role: .system, content: "Provided is text that was transcribed by the user. Please follow their instruction."), Chat(role: .user, content: text)]

                let chatQuery = ChatQuery(model: "gpt-4", messages: chatPrompts, temperature: settings.temperature)
                let result = try await openAI.chats(query: chatQuery)
                text = result.choices[0].message.content ?? "no response"
            } else if mode == .creative {
                recordingState = RecordingStates.transforming
                let content = Clipboard.read()
                let chatPrompts: [Chat] = [Chat(role: .system, content: "First is a set of instructions followed by content to apply the instructions to"), Chat(role: .user, content: text), Chat(role: .user, content: content)]

                let chatQuery = ChatQuery(model: "gpt-4", messages: chatPrompts, temperature: settings.temperature)
                let result = try await openAI.chats(query: chatQuery)
                text = result.choices[0].message.content ?? "no response"
            }                        
            
            let duration = timer.stop()
            let components = text.components(separatedBy: .whitespacesAndNewlines)
            let words = components.filter { !$0.isEmpty }


            let item = HistoryItem(body: text, mode: mode)
            item.duration = duration
            item.wordsPerSecond =  Double(words.count) / duration

            Clipboard.copy(text)
            settings.history.enqueue(item)
            
            if settings.enableSounds {
                playDoneSound()
            }
            if settings.enableAutoPaste {
                paste()
            }
            

            EventTracking.transcription(provider: "Local", mode: mode.rawValue, recordingDuration: recordingDuration, transcriptionDuration: item.duration, numWords: words.count)

        } catch {
            self.showError(error)
        }
        
            self.recordingState = RecordingStates.stopped
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
        try await localTranscription.initModel()
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

    private func transcribeLocal(data: [Float]) async throws -> String {
        try await localTranscription.initModel()
        localTranscription.language = settings.language
        localTranscription.translateToEnglish = settings.translateResultToEnglish
        localTranscription.prompt = "The sentence may be cut off, do not make up words to fill in the rest of the sentence. Don't make up anything that wasn't clearly spoken. Don't include any noises. " + settings.prompt
        return try await withCheckedThrowingContinuation { continuation in
            localTranscription.translateToEnglish = settings.translateResultToEnglish
            localTranscription.language = settings.language
            localTranscription.transcribe(data: data) { result in
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
        if settings.enableSounds {
            playErrorSound()
        }
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


