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
    @State var enableSounds: Bool = false;
    @State var enableOpenAI: Bool = false;
    
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
            
            Group {
                
                Toggle(isOn: $translateResultToEnglish) {
                    Text("Translate to English if speaking another language")
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $enableAutoPaste) {
                    Text("Output text directly to your cursor")
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $enableSounds) {
                    Text("Enable sounds")
                }
                .toggleStyle(.checkbox)
            }
            
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
            
            
            Group {
                KeyboardShortcuts.Recorder("Transcription:", name: .toggleRecordMode)
                
                KeyboardShortcuts.Recorder("Instruction Mode:", name: .toggleInstructionMode).disabled(!enableOpenAI)
                
                KeyboardShortcuts.Recorder("Creative Mode:", name: .toggleCreativeMode).disabled(!enableOpenAI)
            }
            
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
        self.enableSounds = settingsVM.settings.enableSounds
        self.enableOpenAI = settingsVM.settings.enableOpenAI
    }
    
    private func save() {
        let autoPasteJustEnabled: Bool = !settingsVM.settings.enableAutoPaste && enableAutoPaste
        settingsVM.settings.openAIToken = openAIToken
        settingsVM.settings.language = self.language
        settingsVM.settings.prompt = self.prompt
        settingsVM.settings.translateResultToEnglish = self.translateResultToEnglish
        settingsVM.settings.enableAutoPaste = self.enableAutoPaste
        settingsVM.settings.enableSounds = self.enableSounds
        settingsVM.settings.enableOpenAI = self.enableOpenAI
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
