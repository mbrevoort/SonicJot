//
//  App.swift
//
//
//  Created by Mike Brevoort on 8/7/23.
//

import SwiftUI
import MenuBarExtraAccess

@main
struct swiftui_menu_barApp: App {
    @ObservedObject var currentState: AppState = AppState.instance()
    @Environment(\.openWindow) private var openWindow
        
    var body: some Scene {
        MenuBarExtra("SonicJot", systemImage: currentState.recordingState.rawValue) {
            Menu(isMenuPresented: $currentState.isMenuPresented, isSummary: $currentState.isMenuSummary)
            .introspectMenuBarExtraWindow { window in // <-- the magic ✨
                window.animationBehavior = .utilityWindow
            }
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $currentState.isMenuPresented) { statusItem in // <-- the magic ✨
            // access status item or store it in a @State var
        }
        
        
        Window("Settings", id:"settings") {
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
        .windowStyle(.hiddenTitleBar)
        
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

func closeWindow(id: String) {
    for window in NSApplication.shared.windows {
        if window.identifier == NSUserInterfaceItemIdentifier(id) {
            window.close()
            break
        }
    }
}



