//
//  Transcription.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/1/24.
//

import SwiftUI
import ComposableArchitecture


@DependencyClient
struct TranscriptionClient {
    var initialize: () async throws -> Void
    var transcribe: (URL) async throws -> TranscriptionResult
}

extension DependencyValues {
    var transcription: TranscriptionClient {
        get { self[TranscriptionClient.self] }
        set { self[TranscriptionClient.self] = newValue }
    }
}

extension TranscriptionClient: DependencyKey {
    static var liveValue: Self {
        @Dependency(\.settings) var settingsClient
        @Dependency(\.eventTracking) var eventTracking
        
        let localTranscription = LocalTranscription()
        let openAITranscription = OpenAITranscription()
        
        return Self(
            initialize: {
                let settings = try settingsClient.get()
                if !settings.enableOpenAI {
                    try await localTranscription.initModel()
                }
            },
            
            transcribe: { fileURL in
                // TODO: consider refactoring implementations into class with subclasses
                var text = ""
                let settings = try settingsClient.get()
                let timer = Timer()
                if settings.enableOpenAI {
                    openAITranscription.openAIToken = settings.openAIToken
                    openAITranscription.translateToEnglish = settings.translateResultToEnglish
                    text = try await openAITranscription.transcribe(url: fileURL as URL)
                } else {
                    localTranscription.translateToEnglish = settings.translateResultToEnglish
                    text = try await localTranscription.transcribe(url: fileURL as URL)
                }
                
                let provider = settings.enableOpenAI ? EventTracking.TranscriptionProvider.OpenAI : EventTracking.TranscriptionProvider.Local
                let duration = timer.stop()
                let components = text.components(separatedBy: .whitespacesAndNewlines)
                let words = components.filter { !$0.isEmpty }
                let numWords = words.count
                eventTracking.transcription(provider, duration, numWords)
                
                return TranscriptionResult(text: text, words: numWords, duration: duration, date: Date())
            }
        )
    }
}

public struct TranscriptionResult: Equatable {
    var text: String
    var words: Int
    var duration: Double
    var date: Date
    
    static func empty() -> Self {
        return TranscriptionResult(text: "", words: 0, duration: 0.0, date: Date(timeIntervalSince1970: 0))
    }    
}

extension TranscriptionClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        initialize: {},
        transcribe: { _ in TranscriptionResult.empty() }
    )
    
    static let noop = Self(
        initialize: { },
        transcribe: { _ in TranscriptionResult.empty() }
    )
}