//
//  Menu.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/19/23.
//

import SwiftUI

struct Menu: View {
    @ObservedObject var currentState: AppState = AppState.instance()
    @Environment(\.openWindow) private var openWindow
    @Binding var isMenuPresented: Bool
    @Binding var isSummary: Bool
    @State var hover: Bool = false
    
    @State private var isHistoryHovered = false
    @State private var isSettingsHovered = false
    @State private var isAboutHovered = false
    @State private var isQuitHovered = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Spacer().frame(height: 10)
            
            HStack {
                Spacer().frame(width:10)
                Image(systemName: "info.circle")
                Text("\(currentState.runningStatus)")
                    .padding(EdgeInsets(top:0, leading: 0, bottom: 0, trailing: 0))
                    .italic()
                    .foregroundColor(Color(NSColor.labelColor))
                    .font(.system(size: 12))
                Spacer()
                if currentState.recordingState == RecordingStates.recording {
                    recordingAnimation()
                }
                if currentState.recordingState == RecordingStates.working {
                    transcriptionAnimation()
                }
            }
            
            
            Divider()
            
            if !isSummary {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        currentState.startRecording()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Start"))
                    .disabled(currentState.recordingState != RecordingStates.stopped || currentState.isKeyDown)
                    
                    Button(action: {
                        currentState.stopRecording()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Stop"))
                    .disabled(currentState.recordingState != RecordingStates.recording || currentState.isKeyDown)
                    
                    Button(action: {
                        currentState.cancelRecording()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Cancel"))
                    .disabled(currentState.recordingState != RecordingStates.recording || currentState.isKeyDown)
                }
                
                
                Divider()
                
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "history")
                        currentState.hideMenu()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "History"))
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "settings")
                        currentState.hideMenu()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Settings"))
                    
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "about")
                        currentState.hideMenu()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "About"))
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Quit"))
                }
                
            } else {
                Button(action: {
                    self.isSummary = false
                }, label: {})
                .buttonStyle(MenuStyle(title: "Reveal Options"))
                
            }
            
            
        }.padding(EdgeInsets(top:0, leading: 5, bottom: 5, trailing: 10))
    }
    
    @State private var isTranscribing = false
    
    private func transcriptionAnimation() -> some View {
        VStack (alignment: .center, spacing: 1) {
            rod(width: 6, duration: 1.0)
            rod(width: 8, duration: 0.8)
            rod(width: 4, duration: 1.2)
        }
        .frame(width:26)
        .onAppear() {
            self.isTranscribing = true
        }
        .onDisappear() {
            self.isTranscribing = false
        }
    }
    
    private func rod(width: CGFloat = 8, duration: CGFloat = 1) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(.gray.gradient)
                .frame(width: 26, height: 3)
            
            RoundedRectangle(cornerRadius: 3)
                .fill(.indigo.gradient)
                .frame(width: width, height: 3)
                .offset(x: isTranscribing ? 13 : -13, y: 0)
                .animation(Animation.linear(duration: duration).repeatForever(autoreverses: true), value: isTranscribing)
        }
    }
    
    @State private var isRecording = false
    
    private func recordingAnimation() -> some View {
        HStack(alignment: .center, spacing: 1) {
            bar(low:0.4)
                .animation(animateBar.speed(1.5), value: isRecording)
            bar(low:0.3)
                .animation(animateBar.speed(1.2), value: isRecording)
            bar(low:0.4)
                .animation(animateBar.speed(1.0), value: isRecording)
            bar(low:0.5)
                .animation(animateBar.speed(1.5), value: isRecording)
            bar(low:0.3)
                .animation(animateBar.speed(1.7), value: isRecording)
            bar(low:0.5)
                .animation(animateBar.speed(1.0), value: isRecording)
        }
        .frame(width: 26)
        .onAppear() {
            self.isRecording = true
        }
        .onDisappear() {
            self.isRecording = false
        }
    }
    
    private func bar(low: CGFloat = 0.0, high: CGFloat = 1.0) -> some View {
        return RoundedRectangle(cornerRadius: 3)
            .fill(.indigo.gradient)
            .frame(width: 2, height: (isRecording ? high : low) * 16)
            .frame(height: 16)
    }
    
    var animateBar: Animation {
        return .linear(duration:0.5).repeatForever()
    }
}


struct MenuStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    @State var isHovered: Bool = false
    let buttonTitle: String
    let buttonIcon: Image?
    
    init(title: String, icon: Image? = nil) {
        self.buttonTitle = title
        self.buttonIcon = icon
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            Spacer().frame(width:10)
            if buttonIcon != nil {
                buttonIcon
                    .foregroundColor(isEnabled ? isHovered ? Color(NSColor.selectedMenuItemTextColor) : Color(NSColor.labelColor): Color(NSColor.disabledControlTextColor))
            }
            Text(buttonTitle)
                .foregroundColor(isEnabled ? isHovered ? Color(NSColor.selectedMenuItemTextColor) : Color(NSColor.labelColor) : Color(NSColor.disabledControlTextColor))
            Spacer()
            
        }
        .frame(maxWidth:.infinity, minHeight: 25)
        .background(isEnabled ? isHovered ? Color(NSColor.selectedContentBackgroundColor) : Color.clear : Color.clear)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 5,
                style: .continuous
            )
        )
        .onHover { isHovering in
            if isEnabled {
                self.isHovered = isHovering
            }
        }
        .padding(EdgeInsets(top:0, leading: 0, bottom: 0, trailing: 5))
        .font(.system(size: 13))
        .buttonStyle(.borderless)
    }
    
}


