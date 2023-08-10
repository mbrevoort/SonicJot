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
    
    var body: some Scene {
        MenuBarExtra("QuickScribe", systemImage: currentState.state) {
            Button("Start Recording") {
                currentState.startRecording()
            }
            .keyboardShortcut("S")
            .disabled(currentState.state != stopped)

            Button("Stop Recording") {
                currentState.stopRecording()
            }
            .keyboardShortcut("X")
            .disabled(currentState.state == stopped)
            
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
    }
    
    init() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

}


