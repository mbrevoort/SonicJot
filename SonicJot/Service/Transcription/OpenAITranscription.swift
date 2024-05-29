//
//  OpenAITranscription.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/4/24.
//

import SwiftUI
import OpenAI
import Dependencies


final class OpenAITranscription: TranscriptionBase, ObservableObject {
    @Dependency(\.settings) var settingsClient
    
    lazy private var openAI: OpenAI = OpenAI(apiToken: self.openAIToken)
    var openAIToken: String = "" {
        didSet {
            self.openAI = OpenAI(apiToken: self.openAIToken)
        }
    }
        
    enum Errors: Error {
        case openAIAPIKeyNotSet
    }
    
    override func transcribe(url: URL) async throws -> String {
        guard openAIToken != "" else {
            throw Errors.openAIAPIKeyNotSet
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try Data(contentsOf: url as URL)
                let query = AudioTranscriptionQuery(file: data, fileType: AudioTranscriptionQuery.FileType(rawValue: "audio.m4a")!, model: .whisper_1, prompt: self.prompt, language: self.language.rawValue)
                openAI.audioTranscriptions(query: query) { result in
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
}
