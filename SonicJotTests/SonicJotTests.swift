//
//  MenuTests.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/4/24.
//

import ComposableArchitecture
import XCTest
@testable import SonicJot

@MainActor
final class MenuTests: XCTestCase {
    func testMenuTranscription() async {
        let store = TestStore(initialState: MenuReducer.State()) {
            MenuReducer()
        }
        
        await store.send(.initialize)
        await store.receive(\.transcriptionServiceReady) { state in
            state.recordingState = .stopped
        }

        await store.receive(\.updateTotalWords)

        await store.send(.cancelTranscriptionClicked)
        await store.send(.completeTranscriptionClicked)
        
        await store.send(.beginTranscriptionClicked) {
            $0.recordingState = .recording
            $0.lastActivity = nil
        }
        
        await store.send(.completeTranscriptionClicked) {
            $0.recordingState = .transcribing
        }
        
        await store.receive(\.startTranscription)
        
        await store.receive(\.completeTransription) {
            $0.recordingState = .stopped
            $0.isSummary = false
            $0.lastActivity = MenuReducer.LastActivity(transcriptionResult: TranscriptionResult.empty())
        }
        
        await store.receive(\.transcriptionServiceReady)
        await store.receive(\.updateTotalWords)
        
        await store.send(.showSummary) {
            $0.isSummary = true
        }
        
        await store.send(.showMoreClicked) {
            $0.isSummary = false
        }
    }
    
    func testMenuShortcutKeyTranscription() async {
        let store = TestStore(initialState: MenuReducer.State()) {
            MenuReducer()
        }
        
        await store.send(.initialize)
        await store.receive(\.transcriptionServiceReady) { state in
            state.recordingState = .stopped
        }
        await store.receive(\.updateTotalWords)

        await store.send(.shortcutKeyDown)

        await store.receive(\.beginTranscriptionClicked) {
            $0.recordingState = .recording
            $0.lastActivity = nil
        }

        await store.send(.shortcutKeyUp)
            
        await store.receive(\.completeTranscriptionClicked) {
            $0.recordingState = .transcribing
        }
        
        await store.receive(\.startTranscription)
        
        await store.receive(\.completeTransription) {
            $0.recordingState = .stopped
            $0.isSummary = false
            $0.lastActivity = MenuReducer.LastActivity(transcriptionResult: TranscriptionResult.empty())
        }
        
        await store.receive(\.transcriptionServiceReady)
        await store.receive(\.updateTotalWords)
        
        await store.send(.showSummary) {
            $0.isSummary = true
        }
        
        await store.send(.showMoreClicked) {
            $0.isSummary = false
        }
    }
    
    func testTranscriptionError() async {
        let store = TestStore(initialState: MenuReducer.State()) {
            MenuReducer()
        }
        
        await store.send(.initialize)
        await store.receive(\.transcriptionServiceReady) { state in
            state.recordingState = .stopped
        }
        
        await store.receive(\.updateTotalWords)
        
        let activity = MenuReducer.LastActivity(error: "error", date: Date(timeIntervalSince1970: 0))
        await store.send(.transcriptionError("error")) { state in
            state.lastActivity = activity
        }
        
        await store.receive(\.transcriptionServiceReady)
        await store.receive(\.updateTotalWords)
    }
    
}
