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
    @State private var translateResultToEnglish: Bool = false;
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Form {
                Section {
                    TextField("OpenAI API Key:", text: $apiToken)
                    Text("Provide your OpenAI API key from \nhttps://platform.openai.com/account/api-keys").font(.caption)
                    
                    Picker("Speaking Language:", selection: $language) {
                        Text("English").tag("en")
                        Text("German").tag("de")
                        Text("Russian").tag("ru")
                        Text("Spanish").tag("es")
                    }
                    .pickerStyle(MenuPickerStyle())
                    Text("Which language will you be speaking?").font(.caption)
                    
                    LabeledContent {
                        Toggle(isOn: $translateResultToEnglish) {
                            Text("Translate to English")
                        }
                        .toggleStyle(.checkbox)
                    } label: {
                        Text("Translation:")
                    }
                    Text("If speaking in a language other than English, the result can be translated to \nEnglish automatically. Translating from English to English sounds fun but pointless.").font(.caption)
                    
                    LabeledContent {
                        TextEditor(text: $prompt)
                            .lineLimit(3...20)
                            .disableAutocorrection(true)
                    } label: {
                        Text("Speech Hints:")
                    }
                    Text("Provide a sample of something you would normally say and how you would format \nit or some technical terms").font(.caption)
                    
                    KeyboardShortcuts.Recorder("Recording Mode Toggle:", name: .toggleRecordMode)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline) {
                    Button("Cancel") {
                        self.apiToken = currentState.apiToken
                        self.language = currentState.language
                        self.prompt = currentState.prompt
                        self.translateResultToEnglish = currentState.translateResultToEnglish
                        dismiss()
                    }.buttonStyle(.bordered)
                    Button("Save") {
                        self.currentState.apiToken = self.apiToken
                        self.currentState.language = self.language
                        self.currentState.prompt = self.prompt
                        self.currentState.translateResultToEnglish = self.translateResultToEnglish
                        dismiss()
                    }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .onAppear{
                self.apiToken = currentState.apiToken
                self.language = currentState.language
                self.prompt = currentState.prompt
                self.translateResultToEnglish = currentState.translateResultToEnglish
            }
        }
        .frame(width: 600, height: 350)
    }
}


