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

@MainActor
final class AppState: ObservableObject {
    private static var _instance: AppState = AppState()
    public static func instance() -> AppState {
        return _instance
    }
    
    
    @Published var state = stopped
    var apiToken: String = KeychainHelper.getOpenAIToken() {
        didSet {
            KeychainHelper.setOpenAIToken(apiToken)
            self.openAI = OpenAI(apiToken: apiToken)
        }
    }
    lazy public var openAI: OpenAI = OpenAI(apiToken: apiToken)
    let rec = Recording()

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleRecordMode) { [weak self] in
            if self?.state == stopped {
                self?.startRecording()
            } else if self?.state == recording {
                self?.stopRecording()
            }
        }
    }
    
    public func startRecording() {
        print("Api token is \(apiToken)")
        if apiToken == "" {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            return
        }
        
        print("START RECORDING")
        state = recording
        do {
            try rec.record()
        } catch {
            print("error: \(error)")
        }
    }
    
    public func stopRecording() {
        print("STOP RECORDING")
        do {
            state = working
            let url = rec.stop()
            
            
            // handle transcription
            let data = try Data(contentsOf: url as URL)
            let query = AudioTranscriptionQuery(file: data, fileName: "audio.m4a", model: .whisper_1)
            
            self.openAI.audioTranscriptions(query: query) { result in
                print("result: \(result)")
                
                switch result {
                case .success(let data):
                    self.setClipboard(data.text)
                    NSSound.beep()
                case .failure(let error):
                    print("error: \(error)")
                }
                DispatchQueue.main.async {
                    self.state = stopped
                }
            }
        } catch {
            print("error: \(error)")
            state = stopped
        }
    }
     
    func setClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
}
