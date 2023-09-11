//
//  SettingsView.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/27/23.
//

import SwiftUI
import CloudKit
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    @State var openAIToken: String = ""
    @State var temperature: Double = 0.0
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
            .frame(width: 400)
            
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
                
                LaunchAtLogin.Toggle()
                
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
                .frame(minWidth: 400, maxWidth: 400, minHeight: 100)
            } label: {
                Text("Speech Hints:")
            }
            
            KeyboardShortcuts.Recorder("Transcription:", name: .toggleRecordMode)
            Caption("Verbatim, what you say")

            Spacer().frame(height:20)
            
            Group {
                Toggle(isOn: $enableOpenAI) {
                    Text("Enable OpenAI")
                }
                .toggleStyle(.checkbox)
                
                
                SecureField("OpenAI API Key:", text: $openAIToken)
                    .disabled(!enableOpenAI)
                    .labelStyle(.titleAndIcon)
                    .frame(width: 500)
                
                LabeledContent {
                    VStack {
                        Slider(value: $temperature, in: 0...1)
                            .disabled(!enableOpenAI)
                            .frame(width: 400)
                        DisableableText("\(formatTemperatureString(val: temperature))", disabled: !enableOpenAI)
                    }
                } label: {
                    Text("Creativity:")
                }
                
                KeyboardShortcuts.Recorder("Instructive Transcription:", name: .toggleInstructionMode).disabled(!enableOpenAI)
                Caption("Decribe output", disabled: !enableOpenAI)
                
                KeyboardShortcuts.Recorder("Creative Transcription:", name: .toggleCreativeMode).disabled(!enableOpenAI)
                Caption("Reference clipboard contents", disabled: !enableOpenAI)
                
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
        self.temperature = settingsVM.settings.temperature
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
        settingsVM.settings.temperature = formatTemperature(val: temperature)
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
    
    private func formatTemperature(val: Double) -> Double {
        return Double(round(100 * val) / 100)
    }
    
    private func formatTemperatureString(val: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return String(Int(round(100 * formatTemperature(val: val)))) + "%"
    }
    
    private func Caption(_ string: String, disabled: Bool = false) -> Text {
        return DisableableText(string, disabled: disabled).font(.caption)
    }

    private func DisableableText(_ string: String, disabled: Bool = false) -> Text {
        var text = Text(string)
        if disabled {
            text = text.foregroundColor(Color(NSColor.disabledControlTextColor))
        }
        return text
    }

}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        @ObservedObject var settingsVM: SettingsViewModel = SettingsViewModel()
        SettingsView().environmentObject(settingsVM)
    }
}
