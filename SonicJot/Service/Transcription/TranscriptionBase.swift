//
//  TranscriptionBase.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/5/24.
//

import Foundation

enum TranscriptionLanguage: String {
    case English = "en"
    case German = "de"
    case Russian = "ru"
    case Spanish = "es"
}

fileprivate let basePrompt: String = "The sentence may be cut off, do not make up words to fill in the rest of the sentence. Don't make up anything that wasn't clearly spoken. Don't include any background noises. "

class TranscriptionBase {
    internal var prompt: String = basePrompt
    
    func setPrompt(speachHints: String) {
        if speachHints.isEmpty {
            self.prompt = basePrompt
        } else {
            self.prompt = "\(basePrompt) Words may include: \(speachHints)"
        }
    }
    
    var language: TranscriptionLanguage = .English
    var translateToEnglish: Bool = false
    
    func transcribe(url: URL) async throws -> String {
        fatalError("transcribe has not been implemented")
    }
}
