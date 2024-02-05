//
//  App.swift
//
//
//  Created by Mike Brevoort on 8/7/23.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

@main
struct SonicJotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsFeatureView(
                store: Store(initialState: SettingsReducer.State()) {
                    SettingsReducer()
                }
            )
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Dependency(\.menuProxy) var menuProxy
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var isPopoverShown: Bool = false
    
    private var view = MenuView(
        store: Store(initialState: MenuReducer.State()) {
            MenuReducer()
        }
    )
    
    @MainActor func applicationWillFinishLaunching(_ notification: Notification) {
        menuProxy.setAppDelegate(self)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            updateMenuIcon(.initializing)
            statusButton.action = #selector(togglePopover)
        }
        
        self.popover = NSPopover()
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: view)
    }
    
    // TODO: consider moving these functions into the MenuProxy service
    
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }
    
    func openPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            isPopoverShown = true
        }
    }
    
    func closePopover() {
        self.popover.performClose(nil)
        isPopoverShown = false
    }
    
    func isPopoverOpen() -> Bool {
        return isPopoverShown
    }
    
    func updateMenuIcon(_ systemSymbolName: MenuProxyClient.RecordingStateIcon) {
        if let statusButton = statusItem.button {
            DispatchQueue.main.async {
                statusButton.image = NSImage(systemSymbolName: systemSymbolName.rawValue, accessibilityDescription: "SonicJot")
            }
        }
    }
    
}
