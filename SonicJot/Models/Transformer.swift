//
//  Transformer.swift
//  SonicJot
//
//  Created by Mike Brevoort on 9/19/23.
//

import SwiftUI
import Generation
import Models



class Transformer {
    private var config = GenerationConfig(maxNewTokens: 20)
    private var languageModel: LanguageModel? = nil
    
    
    init(modelURL: URL) {
        Task.init() {
            languageModel = try await ModelLoader.load(url: modelURL)
            if let config = languageModel?.defaultGenerationConfig { self.config = config }
            print("LanguageModel: \(languageModel!.description)")
        }
    }
}
