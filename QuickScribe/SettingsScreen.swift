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
                    KeyboardShortcuts.Recorder("Toggle Recording Mode:", name: .toggleRecordMode)
                }
                Section {
                    HStack {
                        Button("Cancel") {
                            self.apiToken = currentState.apiToken
                            dismiss()
                        }
                        Spacer()
                        Button("Save") {
                            self.currentState.apiToken = self.apiToken
                            dismiss()
                        }
                    }
                }
            }
            .frame(width: 400, height: 400)
            .padding()
        }
    }
    
}
