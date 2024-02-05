//
//  SettingsStorage.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/1/24.
//

import Foundation
import SwiftUI
import OpenAI
import ComposableArchitecture

@DependencyClient
struct SettingsClient {
    var get: () throws -> UserSettings
    var set: (UserSettings) -> Void
    var now: () -> Date = { Date() }
}

extension DependencyValues {
    var settings: SettingsClient {
        get { self[SettingsClient.self] }
        set { self[SettingsClient.self] = newValue}
    }
}

extension SettingsClient: DependencyKey {
    static var liveValue: Self {
        let service = SettingsService()
        
        return Self(
            get: {
                return UserSettings(enableOpenAI: service.enableOpenAI,
                                language: service.language,
                                translateResultToEnglish: service.translateResultToEnglish,
                                enableAutoPaste: service.enableAutoPaste,
                                enableSounds: service.enableSounds,
                                prompt: service.prompt,
                                openAIToken: service.openAIToken)
            },
            set: { settings in
                service.enableOpenAI = settings.enableOpenAI
                service.language = settings.language
                service.translateResultToEnglish = settings.translateResultToEnglish
                service.enableAutoPaste = settings.enableAutoPaste
                service.enableSounds = settings.enableSounds
                service.prompt = settings.prompt
                service.openAIToken = settings.openAIToken
            },
            now: {
                return Date()
            }
        )
    }
}

public struct UserSettings: Equatable {
    var enableOpenAI: Bool = false
    var language: TranscriptionLanguage = .English
    var translateResultToEnglish: Bool = false
    var enableAutoPaste: Bool = false
    var enableSounds: Bool = false
    var prompt: String = ""
    var openAIToken: String = ""
}


class SettingsService: ObservableObject {
    private let obf = Obfuscator()
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    
    init() {
        self.openAIToken = self.openAITokenEnc
    }
    
    @AppStorage("enableOpenAI") var enableOpenAI: Bool = false
    @AppStorage("language") var language: TranscriptionLanguage = .English
    @AppStorage("translateResultToEnglish") var translateResultToEnglish: Bool = false
    @AppStorage("enableAutoPaste") var enableAutoPaste: Bool = false
    @AppStorage("enableSounds") var enableSounds: Bool = true
    @AppStorage("prompt") var prompt: String = "Hello, nice to see you today!"
    
    // Store an obfuscated version of the openaikey in app storage. This is not "secure"
    // but it will make it a big more challenging to discover. Originally the keychain was
    // used but it caused users to have to enter their admin creditals which was annoying. On
    // Mac, there are user credentials strewn all along the file system in dot files and so on.
    // For now this is acceptable
    @AppStorage("serializedoaik") private var servializedOpenAIToken: String = ""
    
    @Published public var openAIToken: String = "" {
        didSet {
            openAITokenEnc = openAIToken
        }
    }
    private var openAITokenEnc: String {
        set {
            servializedOpenAIToken = obf.stringByObfuscatingString(string: newValue)
            // TODO: watch somewhere so OpenAI client can be updated
        }
        get {
            return obf.revealStringByString(string: servializedOpenAIToken)
        }
    }
}

extension SettingsClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        get: { UserSettings() },
        set: { _ in  },
        now: { Date(timeIntervalSince1970: 0) }
    )
    
    static let noop = Self(
        get: { UserSettings() },
        set: { _ in  },
        now: { Date(timeIntervalSince1970: 0) }
    )
}
