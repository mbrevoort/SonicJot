//
//  QuickScribeApp.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/7/23.
//

import SwiftUI

@main
struct swiftui_menu_barApp: App {
    @ObservedObject var currentState: AppState = AppState.instance()
    @Environment(\.openWindow) private var openWindow
        
    var body: some Scene {
        MenuBarExtra("QuickScribe", systemImage: currentState.recordingState) {
            Button("Start Recording") {
                currentState.startRecording()
            }
            .keyboardShortcut("S")
            .disabled(currentState.recordingState != stopped)

            Button("Stop Recording") {
                currentState.stopRecording()
            }
            .keyboardShortcut("X")
            .disabled(currentState.recordingState == stopped)

            Button("Cancel Recording") {
                currentState.cancelRecording()
            }
            .disabled(currentState.recordingState == stopped)

            
            Button("History") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "history")
            }
            .keyboardShortcut("H")

            Divider()
            
            Button("Preferences") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
                        
        }
        Settings {
            SettingsScreen()
        }
        Window("History", id:"history") {
            HistoryScreen()
        }
    }
    
    func showError(_ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "error")
    }

    
    init() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

}


