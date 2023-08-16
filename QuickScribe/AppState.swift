//
//  AppState.swift
//  QuickScribe
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

    @Published var recordingState = stopped
    
    @AppStorage("language") var language: String = "en"
    @AppStorage("translateResultToEnglish") var translateResultToEnglish: Bool = false
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
        KeyboardShortcuts.onKeyUp(for: .toggleRecordMode) { [weak self] in
            if self?.recordingState == stopped {
                self?.startRecording()
            } else if self?.recordingState == recording {
                self?.stopRecording()
            }
        }
        
        // Hydrade saved history
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
    
    public func startRecording() {
        if apiToken == "" {
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
    
    // TODO: reflactor
    public func stopRecording() {
        print("STOP RECORDING")
        do {
            recordingState = working
            let url = rec.stop()
            let data = try Data(contentsOf: url as URL)
            
            if self.translateResultToEnglish {
                // handle tranlation transcription
                let query = AudioTranslationQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: self.prompt)
                self.openAI.audioTranslations(query: query) { result in
                    print("Translation result: \(result)")
                    switch result {
                    case .success(let data):
                        self.handleTranscriptionSuccess(data.text)
                    case .failure(let error):
                        self.showError(error)
                    }
                    
                    DispatchQueue.main.async {
                        self.recordingState = stopped
                    }
                }
            } else {
                // handle transcription
                let query = AudioTranscriptionQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: self.prompt, language: self.language)
                self.openAI.audioTranscriptions(query: query) { result in
                    print("Transcription result: \(result)")
                    switch result {
                    case .success(let data):
                        self.handleTranscriptionSuccess(data.text)
                    case .failure(let error):
                        self.showError(error)
                    }
                    
                    DispatchQueue.main.async {
                        self.recordingState = stopped
                    }
                }                
            }
        } catch {
            self.showError(error)
            recordingState = stopped
        }
    }
    
    private func handleTranscriptionSuccess(_ text: String) {
        logger.info("result: \(text)")
        AppState.setClipboard(text)
        self.history.enqueue(HistoryItem(text))
        playOKSound()
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
    
}

