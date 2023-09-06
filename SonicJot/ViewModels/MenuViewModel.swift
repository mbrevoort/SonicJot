//
//  MenuViewModel.swift
//  SonicJot
//
//  Created by Mike Brevoort on 9/1/23.
//

import Foundation
import OpenAI
import KeyboardShortcuts
import Cocoa
import SwiftUI
import Combine

class MenuViewModel: ObservableObject {
    @Published var settings: SettingsModel = SettingsModel.instance()
    @Published var transcription: TranscriptionModel = TranscriptionModel()
    
    public var runningStatus: String {
        get {
            switch transcription.recordingState {
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
    
    @Published var isMenuPresented: Bool = false
    @Published var isMenuSummary: Bool = false
    @Published public var isKeyDown: Bool = false
    private var lastKeyDownTime: Date?

    var changeSink: AnyCancellable?
    var settingsChangeSink: AnyCancellable?

    init() {
        // Register keyboard shortcuts
        KeyboardShortcuts.onKeyDown(for: .toggleRecordMode) { [weak self] in
            self?.keyDown()
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleRecordMode) { [weak self] in
            self?.keyUp()
        }
                
        changeSink = transcription.$recordingState.sink { _ in
            self.objectWillChange.send()
        }
        
        settingsChangeSink = settings.$openAIToken.sink {
            self.transcription.refreshOpenAI(updatedToken: $0)
        }
    }
    
    private func keyDown() {
        if transcription.recordingState == RecordingStates.working {
            return
        }
        
        self.isKeyDown = true
        lastKeyDownTime = Date()
        
        if transcription.recordingState == RecordingStates.stopped {
            self.isMenuSummary = true
            do {
                try transcription.startRecording()
                isMenuPresented = true
            } catch {
                self.showError(error)
            }
        } else if transcription.recordingState == RecordingStates.recording {
            self.stopRecording()
        }
    }
    
    private func keyUp() {
        self.isKeyDown = false
        let sinceLastKeyDown = abs(self.lastKeyDownTime?.timeIntervalSinceNow ?? 0)
        print("sinceLastKeyDown: \(sinceLastKeyDown)")
        let wasHeldDown: Bool = sinceLastKeyDown > 0.7 //seconds
        let isRecording: Bool = transcription.recordingState == RecordingStates.recording
        if wasHeldDown && isRecording {
            self.stopRecording()
        }
    }
    
    public func hideMenu() {
        isMenuPresented = false
//        DispatchQueue.main.async {
            self.isMenuSummary = false
//        }
    }
    
    public func openSummaryMenu() {
        isMenuSummary = true
        isMenuPresented = true
    }

    public func openMenu() {
        isMenuSummary = false
        isMenuPresented = true
    }
    
    
    public func startRecording() {
        isMenuPresented = true
        do {
            try transcription.startRecording()
        } catch {
            self.showError(error)
        }
    }
    
    public func stopRecording() {
        Task {
            await transcription.stopRecording()
            DispatchQueue.main.async {
                self.hideMenu()
            }
        }
    }
    
    public func cancelRecording() {
        transcription.cancelRecording()
        hideMenu()
    }
    
    func showError(_ err: any Error) {
        playErrorSound()
        print("error: \(err)")
        logger.error("error: \(err)")
        settings.history.enqueue(HistoryItem(body: "\(err)", type: HistoryItemType.error))
    }
    
    // Based on https://github.com/p0deje/Maccy/blob/master/Maccy/Clipboard.swift
    func paste() {
        guard settings.accessibilityAllowed else {
            // Show accessibility window async to allow menu to close.
            DispatchQueue.main.async{
                self.settings.showAccessibilityWindow()
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
    

    
    

}
