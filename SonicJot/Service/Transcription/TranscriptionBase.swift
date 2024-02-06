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


fileprivate func makePrompt(language: TranscriptionLanguage, speachHints: String) -> String {
    let basePrompts: [TranscriptionLanguage: String] = [
        .English: "The sentence may be cut off, do not make up words to fill in the rest of the sentence. Don't make up anything that wasn't clearly spoken. Don't include any background noises. ",
        .Spanish: "La frase puede estar cortada, no inventes palabras para completar el resto de la frase. No inventes nada que no se haya dicho claramente. No incluyas ningún ruido de fondo.",
        .German: "Der Satz könnte abgeschnitten sein, ergänzen Sie keine Wörter, um den Rest des Satzes zu füllen. Erfinden Sie nichts, was nicht deutlich gesprochen wurde. Schließen Sie keine Hintergrundgeräusche ein.",
        .Russian: "Предложение может быть оборвано, не добавляйте слов, чтобы заполнить остаток предложения. Не выдумывайте ничего, что не было ясно сказано. Не включайте фоновые шумы.",
    ]
    let speachHintLead: [TranscriptionLanguage: String] = [
        .English: "Words may include:",
        .Spanish: "Las palabras pueden incluir:",
        .German: "Wörter können beinhalten:",
        .Russian: "Слова могут включать:",
    ]
    
    if speachHints.isEmpty {
        return basePrompts[language, default: basePrompts[.English]!]
    } else {
        return basePrompts[language, default: basePrompts[.English]!] + " " + speachHintLead[language, default: speachHintLead[.English]!] + " " + speachHints
    }
}

class TranscriptionBase {
    internal var prompt: String = makePrompt(language: .English, speachHints: "")
    var language: TranscriptionLanguage = .English

    func setPrompt(speachHints: String) {
        self.prompt = makePrompt(language: self.language, speachHints: speachHints)
    }    
    
    func transcribe(url: URL) async throws -> String {
        fatalError("transcribe has not been implemented")
    }
}
