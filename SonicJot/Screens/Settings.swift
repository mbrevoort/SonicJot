//
//  SettingsScreen.swift
//  SonicJot
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
    @State private var enableAutoPaste: Bool = false;
    @State private var useOpenAI: Bool = false;
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Form {
                Section {
                    
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
                            Text("Translate to English if speaking another language")
                        }
                        .toggleStyle(.checkbox)
                    } label: {
                        Text("Translation:")
                    }

                    LabeledContent {
                        Toggle(isOn: $enableAutoPaste) {
                            Text("Output text at cursor when keyboard shortcut is held")
                        }
                        .toggleStyle(.checkbox)
                    } label: {
                        Text("Autotype:")
                    }

                    
                    LabeledContent {
                        ZStack {
                            TextEditor(text: $prompt)
                                .lineLimit(3...20)
                                .disableAutocorrection(true)
                        }
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0))
                        .background(Color.white)
                        .cornerRadius(5)
                    } label: {
                        Text("Speech Hints:")
                    }
                    Text("Provide a sample of something you would normally say and how you would format \nit or some technical terms").font(.caption)
                    
                    LabeledContent {
                        VStack(alignment: .leading) {
                            Toggle(isOn: $useOpenAI) {
                                Text("Enable OpenAI")
                            }
                            .toggleStyle(.checkbox)
                            SecureField("OpenAI API Key", text: $apiToken).disabled(!useOpenAI).labelsHidden()
                            Text("Provide your OpenAI API key from \nhttps://platform.openai.com/account/api-keys").font(.caption)
                        }
                    } label: {
                        Text("OpenAI Options:")
                    }


                    KeyboardShortcuts.Recorder("Record Keyboard Shortcut:", name: .toggleRecordMode)


                }
                Spacer()
                HStack(alignment: .firstTextBaseline) {
                    Button("Cancel") {
                        self.apiToken = currentState.apiToken
                        self.language = currentState.language
                        self.prompt = currentState.prompt
                        self.translateResultToEnglish = currentState.translateResultToEnglish
                        self.enableAutoPaste = currentState.enableAutoPaste
                        self.useOpenAI = currentState.useOpenAI
                        dismiss()
                    }.buttonStyle(.bordered)
                    Button("Save") {
                        let autoPasteJustEnabled: Bool = !self.currentState.enableAutoPaste && self.enableAutoPaste
                        self.currentState.apiToken = self.apiToken
                        self.currentState.language = self.language
                        self.currentState.prompt = self.prompt
                        self.currentState.translateResultToEnglish = self.translateResultToEnglish
                        self.currentState.enableAutoPaste = self.enableAutoPaste
                        self.currentState.useOpenAI = self.useOpenAI
                        dismiss()

                        if autoPasteJustEnabled {
                            self.currentState.showAccessibilityWindow()
                        }
                    }.buttonStyle(.borderedProminent)
                }
            }
            .padding(EdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20))
            .onAppear{
                self.apiToken = currentState.apiToken
                self.language = currentState.language
                self.prompt = currentState.prompt
                self.translateResultToEnglish = currentState.translateResultToEnglish
                self.enableAutoPaste = currentState.enableAutoPaste
                self.useOpenAI = currentState.useOpenAI
            }
        }
        .frame(width: 600, height: 450)
    }
}


