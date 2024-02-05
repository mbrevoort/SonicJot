//
//  Settings.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/2/24.
//

import Combine
import SwiftUI
import Foundation
import ComposableArchitecture
import KeyboardShortcuts

@Reducer
public struct SettingsReducer {
    @Dependency(\.settings) var settings
    @Dependency(\.accessibilityPermissions) var accessibilityPermissions
    
    //MARK: - State
    @ObservableState
    public struct State: Equatable {
        var enableAutoPaste: Bool = false
        var enableOpenAI: Bool = false
        var enableSounds: Bool = true
        var isInitialized: Bool = false
        var language: TranscriptionLanguage = .English
        var openAIToken: String = ""
        var prompt: String = "Hello, it's nice to see you today!"
        var temperature: Double = 0.0
        var translateResultToEnglish: Bool = false
    }
    
    //MARK: - Action
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case initialize
        case loadSettings(UserSettings)
    }
    
    //MARK: - Reducer
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding(\.enableAutoPaste):
                guard state.isInitialized else {
                    return .none
                }
                // TODO: Consider if permissions weren't granted or redacted (vs naively updating toggle
                if state.enableAutoPaste {
                    accessibilityPermissions.prompt()
                }
                fallthrough
            case .binding:
                settings.set(UserSettings(
                    enableOpenAI: state.enableOpenAI,
                    language: state.language,
                    translateResultToEnglish: state.translateResultToEnglish,
                    enableAutoPaste: state.enableAutoPaste,
                    enableSounds: state.enableSounds,
                    prompt: state.prompt,
                    openAIToken: state.openAIToken)
                )
                return .none
            case .initialize:
                return .run { send in
                    let loaded = try settings.get()
                    await send(.loadSettings(loaded))
                }
            case let .loadSettings(loaded):
                state.enableOpenAI = loaded.enableOpenAI
                state.language = loaded.language
                state.translateResultToEnglish = loaded.translateResultToEnglish
                state.enableAutoPaste = loaded.enableAutoPaste
                state.enableSounds = loaded.enableSounds
                state.prompt = loaded.prompt
                state.openAIToken = loaded.openAIToken
                state.isInitialized = true
                return .none
            }
        }
    }
}

struct SettingsFeatureView: View {
    @Bindable var store: StoreOf<SettingsReducer>
    
    public init(store: StoreOf<SettingsReducer>) {
        self.store = store
        store.send(.initialize)
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Group {
                Form {
                    Picker("Speaking Language:", selection: $store.language) {
                        Text("English").tag(TranscriptionLanguage.English)
                        Text("German").tag(TranscriptionLanguage.German)
                        Text("Russian").tag(TranscriptionLanguage.Russian)
                        Text("Spanish").tag(TranscriptionLanguage.Spanish)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 400)
                    
                    LabeledContent {
                        VStack(alignment: .leading) {
                            Toggle(isOn: $store.translateResultToEnglish) {
                                Text("Translate to English")
                            }
                            
                            Toggle(isOn: $store.enableAutoPaste) {
                                Text("Automatically paste transcription")
                            }
                            
                            Caption("Must enable Accessibility Permissions for SonicJot when prompted")
                                .padding(EdgeInsets(top: 0, leading: 20, bottom: 5, trailing: 0))
                            
                            Toggle(isOn: $store.enableSounds) {
                                Text("Enable sounds")
                            }
                            // Launch at Login?
                        }
                    } label: {
                        Text("Options")
                    }
                    
                    
                    Group {
                        
                    }
                    
                    LabeledContent {
                        TextEditor(text: $store.prompt)
                            .lineLimit(3...20)
                            .disableAutocorrection(true)
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0))
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(5)
                            .scrollDisabled(true)
                        
                    } label: {
                        Text("Speech Hints:")
                    }
                    
                    KeyboardShortcuts.Recorder("Keyboard Shortcut:", name: .toggleRecordMode)
                    HStack {
                        Image(systemName: "speaker.wave.2.bubble.fill")
                            .imageScale(.small)
                        Caption("Hold and speak")
                    }
                    
                    Spacer().frame(height:30)
                    Toggle(isOn: $store.enableOpenAI) {
                        Text("Use OpenAI for Transcription")
                    }
                    SecureField(text: $store.openAIToken) {
                        DisableableText("OpenAI API Key:", disabled: !$store.enableOpenAI.wrappedValue)
                    }.disabled(!$store.enableOpenAI.wrappedValue)
                }
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20))
                
            }
            .frame(width: 600)
            
            VStack(alignment: .center) {
                AboutView(
                    store: Store(initialState: AboutReducer.State()) {
                        AboutReducer()
                    }
                ).padding(EdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20))
            }.frame(width: 400, height: 400)
        }
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20))
        .frame(minHeight: 400)
        
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
        return DisableableText(string, disabled: disabled).font(.caption).italic()
    }
    
    private func DisableableText(_ string: String, disabled: Bool = false) -> Text {
        var text = Text(string)
        if disabled {
            text = text.foregroundColor(Color(NSColor.disabledControlTextColor))
        }
        return text
    }
    
    
}

#Preview {
    SettingsFeatureView(
        store: Store(initialState: SettingsReducer.State()) {
            SettingsReducer()
                ._printChanges()
        }
    )
}
