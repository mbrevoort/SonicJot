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


@MainActor
final class AppState: ObservableObject {
    private static var _instance: AppState = AppState()
    public static func instance() -> AppState {
        return _instance
    }
    
    var language: String = "en"
    var prompt: String = "Hello, nice to see you today!"
    @Published var recordingState = stopped
    // TODO: can use @AppStorage?
    var history: FixedQueue<HistoryItem> = FixedQueue<HistoryItem>()
    
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
            if self?.recordingState == stopped {
                self?.startRecording()
            } else if self?.recordingState == recording {
                self?.stopRecording()
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
    
    public func stopRecording() {
        print("STOP RECORDING")
        do {
            recordingState = working
            let url = rec.stop()
            
            
            // handle transcription
            let data = try Data(contentsOf: url as URL)
            let query = AudioTranscriptionQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: self.prompt, language: self.language)
            
            self.openAI.audioTranscriptions(query: query) { result in
                print("result: \(result)")
                
                
                switch result {
                case .success(let data):
                    logger.info("result: \(data.text)")
                    self.setClipboard(data.text)
                    self.history.enqueue(HistoryItem(data.text))
                    playOKSound()
                case .failure(let error):
                    self.showError(error)
                }
                DispatchQueue.main.async {
                    self.recordingState = stopped
                }
            }
        } catch {
            self.showError(error)
            recordingState = stopped
        }
    }
    
    public func cancelRecording() {
        print("CANCEL RECORDING")
        recordingState = stopped
        let url = rec.stop()
    }
    
    
    func setClipboard(_ text: String) {
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

struct FixedQueue<T>: CustomStringConvertible{
    
    private var elements: [T] = []
    private var size: Int = 10
    
    var isEmpty: Bool {
        elements.isEmpty
    }
    
    var peek: T? {
        elements.first
    }
    
    var description: String {
        if isEmpty { return "FixedQueue of \(size) is empty ..."}
        return "---- Queue of length \(size) start ----\n"
        + elements.map({"\($0)"}).joined(separator: " -> ")
        + "\n---- Queue End ----"
    }
    
    mutating func enqueue(_ value: T) {
        if elements.count == self.size {
            _ = self.dequeue()
        }
        elements.append(value)
    }
    
    mutating func dequeue() -> T? {
        isEmpty ? nil : elements.removeFirst()
    }
    
    func list() -> [T] {
        elements.reversed()
    }
    
    init(size: Int) {
        self.size = size
    }
    
    init() {
        self.size = 10
    }
}

enum HistoryItemType {
    case error, transcription
}

class HistoryItem: Identifiable {
    var type: HistoryItemType = HistoryItemType.transcription
    var body: String
    var time: Date
    
    var description: String {
        "\(type): \(body)"
    }
    
    var friendlyType: String {
        switch self.type {
        case HistoryItemType.error:
            return "Error"
        case HistoryItemType.transcription:
            return "Transcription"
        }
    }
    
    init(_ body: String) {
        self.body = body
        self.type = HistoryItemType.transcription
        self.time = Date()
    }
    
    init(body: String, type: HistoryItemType) {
        self.body = body
        self.type = type
        self.time = Date()
    }
    init(body: String, type: HistoryItemType, time: Date) {
        self.body = body
        self.type = type
        self.time = time
    }
}
