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
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    
    @ObservedObject var settingsVM: SettingsViewModel = SettingsViewModel()
    @ObservedObject var menuVM: MenuViewModel = MenuViewModel()
        
    var body: some Scene {
        MenuBarExtra("SonicJot", systemImage: menuVM.transcription.recordingState.rawValue) {
            MenuView(isSummary: $menuVM.isMenuSummary)
            .introspectMenuBarExtraWindow { window in // <-- the magic ✨
                window.animationBehavior = .utilityWindow
            }
            .environmentObject(menuVM)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $menuVM.isMenuPresented) { statusItem in // <-- the magic ✨
            // access status item or store it in a @State var
        }
        
        
        Window("Settings", id:"settings") {
            SettingsView()
                .environmentObject(settingsVM)
        }
        .windowResizabilityContentSize()
        
        Window("History", id:"history") {
            HistoryView()
                .environmentObject(settingsVM)
        }
        
        Window("About", id:"about") {
            AboutView()
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



