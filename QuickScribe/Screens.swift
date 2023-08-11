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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section {
                    TextField("OpenAI API Key:", text: $apiToken)
                        .onAppear {
                            self.apiToken = currentState.apiToken
                        }
                    Text("Provide your OpenAI API key from \nhttps://platform.openai.com/account/api-keys").font(.caption)
                    KeyboardShortcuts.Recorder("Recording Mode Toggle:", name: .toggleRecordMode)
                }
                HStack(alignment: .firstTextBaseline) {
                    Button("Cancel") {
                        self.apiToken = currentState.apiToken
                        dismiss()
                    }.buttonStyle(.bordered)
                    Button("Save") {
                        self.currentState.apiToken = self.apiToken
                        dismiss()
                    }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

