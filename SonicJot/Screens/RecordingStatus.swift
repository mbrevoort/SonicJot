//
//  RecordingStatus.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/18/23.
//

import SwiftUI

struct RecordingStatus: View {
    var body: some View {
        Text("Recording Status")
    }
}

struct RecordingStatus_Previews: PreviewProvider {
    static var previews: some View {
        RecordingStatus()
    }
}

import AppKit

struct ContentView: View {
    @State private var isShowingWindow = false
    
    var body: some View {
        Button("Show window") {
            self.isShowingWindow = true
        }
    }
}

extension ContentView {
    func showWindow() {
        let window = NSWindow()
        window.contentView = NSHostingView(rootView: Text("This is a window without a title or close button."))
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}

