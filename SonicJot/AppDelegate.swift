//
//  AppDelegate.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/21/23.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    @ObservedObject var currentState: AppState = AppState.instance()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Uncomment to make the app show in the dock and in cmd-tab
        // NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    // Detect when the app becomes active and open menu window, this works from spotlight
    // as an alterative in case the menubar is truncated.
    func applicationDidBecomeActive(_ notification: Notification) {
        // print("OPEN")
        
        // not quite what I want, disbaled for now
        // currentState.openMenu()
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        EventTracking.initialize()
    }
    
    
}
