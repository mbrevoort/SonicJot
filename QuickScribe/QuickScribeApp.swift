//
//  QuickScribeApp.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/7/23.
//

import SwiftUI
import HotKey

let recording = "record.circle.fill"
let stopped = "record.circle"

@main
struct swiftui_menu_barApp: App {
    @State var isRecording = false
    @State var currentState: String = stopped
    let hotkey = HotKey(key: .f12, modifiers: [])
    
    private func startRecording() {
        isRecording = true
        currentState = recording
        print("start")
    }
    
    private func stopRecording() {
        isRecording = false
        currentState = stopped
        print("stop")
    }

    
    var body: some Scene {
        MenuBarExtra(currentState, systemImage: currentState) {
            Button("Start") {
                startRecording()
            }
            .keyboardShortcut("S")
            .disabled(isRecording)

            Button("Stop") {
                stopRecording()
            }
            .keyboardShortcut("X")
            .disabled(!isRecording)
            
            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
            
        }
    }
    
    init() {
        hotkey.keyDownHandler = startRecording
        hotkey.keyUpHandler = stopRecording
        print("init")
    }
    

}
