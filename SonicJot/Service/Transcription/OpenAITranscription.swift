//
//  OpenAITranscription.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/4/24.
//

import SwiftUI
import OpenAI
import Dependencies


final class OpenAITranscription: ObservableObject {
    @Dependency(\.settings) var settingsClient
    
    lazy private var openAI: OpenAI = OpenAI(apiToken: self.openAIToken)
    var openAIToken: String = "" {
        didSet {
            self.openAI = OpenAI(apiToken: self.openAIToken)
        }
    }
    
    var prompt: String = "The sentence may be cut off, do not make up words to fill in the rest of the sentence. Don't make up anything that wasn't clearly spoken. Don't include any background noises. "
    var language: TranscriptionLanguage = .English
    var translateToEnglish: Bool = false
    
    enum Errors: Error {
        case openAIAPIKeyNotSet
    }
    
    
    func transcribe(url: URL) async throws -> String {
        guard openAIToken != "" else {
            throw Errors.openAIAPIKeyNotSet
        }
        if translateToEnglish {
            return try await transcribeWithTranslation(url: url)
        }

        return try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try Data(contentsOf: url as URL)
                let query = AudioTranscriptionQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: self.prompt, language: self.language.rawValue)
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
    
    private func transcribeWithTranslation(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try Data(contentsOf: url as URL)
                let query = AudioTranslationQuery(file: data, fileName: "audio.m4a", model: .whisper_1, prompt: self.prompt)
                openAI.audioTranslations(query: query) { result in
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
