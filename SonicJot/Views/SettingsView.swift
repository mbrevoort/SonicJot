//
//  SettingsView.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/27/23.
//

import SwiftUI
import CloudKit
import KeyboardShortcuts



struct SettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    @State var openAIToken: String = ""
    @State var language: String = ""
    @State var prompt: String = ""
    @State var translateResultToEnglish: Bool = false;
    @State var enableAutoPaste: Bool = false;
    @State var enableOpenAI: Bool = false;
    @State var openAIMode: Modes = Modes.transcription
    
    
    var body: some View {
        Spacer()
        Form {
            
            
            Picker("Speaking Language:", selection: $language) {
                Text("English").tag("en")
                Text("German").tag("de")
                Text("Russian").tag("ru")
                Text("Spanish").tag("es")
            }
            .pickerStyle(MenuPickerStyle())
            
            Toggle(isOn: $translateResultToEnglish) {
                Text("Translate to English if speaking another language")
            }
            .toggleStyle(.checkbox)
            
            Toggle(isOn: $enableAutoPaste) {
                Text("Output text directly to your cursor")
            }
            .toggleStyle(.checkbox)
            
            
            LabeledContent {
                ZStack {
                    TextEditor(text: $prompt)
                        .lineLimit(3...20)
                        .disableAutocorrection(true)
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0))
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(5)
            } label: {
                Text("Speech Hints:")
            }
            
            Toggle(isOn: $enableOpenAI) {
                Text("Enable OpenAI")
            }
            .toggleStyle(.checkbox)
            
            
            SecureField("OpenAI API Key", text: $openAIToken)
                .disabled(!enableOpenAI)
                .labelStyle(.titleAndIcon)
            
            Picker("Mode:", selection: $openAIMode) {
                Text("Transcription").tag(Modes.transcription)
                Text("Instruction (experimental)").tag(Modes.instruction)
                Text("Creative (experimental)").tag(Modes.creative)
            }
            .disabled(!enableOpenAI)
            .pickerStyle(.radioGroup)
            
            KeyboardShortcuts.Recorder("Record Keyboard Shortcut:", name: .toggleRecordMode)
            
            
            
            Spacer()
            HStack(alignment: .firstTextBaseline) {
                Button("Cancel") {
                    reset()
                    dismiss()
                }.buttonStyle(.bordered)
                Button("Save") {
                    save()
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20))
        .onAppear{
            reset()
        }
        
    }
    
    private func reset() {
        self.openAIToken = settingsVM.settings.openAIToken
        self.language = settingsVM.settings.language
        self.prompt = settingsVM.settings.prompt
        self.translateResultToEnglish = settingsVM.settings.translateResultToEnglish
        self.enableAutoPaste = settingsVM.settings.enableAutoPaste
        self.enableOpenAI = settingsVM.settings.enableOpenAI
        self.openAIMode = settingsVM.settings.openAIMode
    }
    
    private func save() {
        let autoPasteJustEnabled: Bool = !settingsVM.settings.enableAutoPaste && enableAutoPaste
        settingsVM.settings.openAIToken = openAIToken
        settingsVM.settings.language = self.language
        settingsVM.settings.prompt = self.prompt
        settingsVM.settings.translateResultToEnglish = self.translateResultToEnglish
        settingsVM.settings.enableAutoPaste = self.enableAutoPaste
        settingsVM.settings.enableOpenAI = self.enableOpenAI
        settingsVM.settings.openAIMode = self.openAIMode
        dismiss()
        
        if autoPasteJustEnabled {
            settingsVM.settings.showAccessibilityWindow()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        @ObservedObject var settingsVM: SettingsViewModel = SettingsViewModel()
        SettingsView().environmentObject(settingsVM)
    }
}
