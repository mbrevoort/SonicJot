//
//  SettingsScreen.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/9/23.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsScreen: View {
    @ObservedObject var currentState: AppState = AppState.instance()
    @State private var apiToken: String = ""
    @State private var language: String = ""
    @State private var prompt: String = ""
    @Environment(\.dismiss) var dismiss
    
    let labels = [
        "en" : "🇺🇸 EN",
        "de" : "🇩🇪 DE",
        "ru" : "🇷🇺 RU"
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Form {
                Section {
                    TextField("OpenAI API Key:", text: $apiToken)
                    Text("Provide your OpenAI API key from \nhttps://platform.openai.com/account/api-keys").font(.caption)
                    
                    Picker("Language:", selection: $language) {
                        Text("English").tag("en")
                        Text("German").tag("de")
                        Text("Russian").tag("ru")
                        Text("Spanish").tag("es")
                    }
                    .pickerStyle(MenuPickerStyle())
                    Text("Which language will you be speaking?").font(.caption)
                    
                    TextField("Speech Hints:", text: $prompt, axis: .vertical)
                        .lineLimit(10)
                    Text("Provide a sample of something you would normally say and \nhow you would format it or some technical terms").font(.caption)

                    KeyboardShortcuts.Recorder("Recording Mode Toggle:", name: .toggleRecordMode)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline) {
                    Button("Cancel") {
                        self.apiToken = currentState.apiToken
                        self.language = currentState.language
                        self.prompt = currentState.prompt
                        dismiss()
                    }.buttonStyle(.bordered)
                    Button("Save") {
                        self.currentState.apiToken = self.apiToken
                        self.currentState.language = self.language
                        self.currentState.prompt = self.prompt
                        dismiss()
                    }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .onAppear{
                self.apiToken = currentState.apiToken
                self.language = currentState.language
                self.prompt = currentState.prompt
            }
        }
    }
}

