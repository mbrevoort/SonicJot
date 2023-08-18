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
            Button{
                currentState.startRecording()
            } label: {
                Image(systemName: recording)
                Text("Start Transcription")
            }
            .disabled(currentState.recordingState != stopped)

            Button{
                currentState.stopRecording()
            } label: {
                Image(systemName: "stop")
                Text("Complete Transcription")
            }
            .disabled(currentState.recordingState == stopped)

            Button {
                currentState.cancelRecording()
            } label: {
                Image(systemName: "xmark.square")
                Text("Cancel")
            }
            .disabled(currentState.recordingState == stopped)

            
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "history")
            } label: {
                Image(systemName: "clock")
                Text("History")
            }

            Divider()
            
            Button("Settings") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Button("About") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "about")
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
                        
        }
        Settings {
            SettingsScreen()
        }
        .windowResizabilityContentSize()
        Window("History", id:"history") {
            HistoryScreen()
        }
        Window("About", id:"about") {
            AboutScreen()
        }
        .windowResizabilityContentSize()
    }
    
    func showError(_ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "error")
    }

    
    init() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

}


extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}
