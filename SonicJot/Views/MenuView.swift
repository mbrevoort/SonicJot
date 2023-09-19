//
//  Menu.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/19/23.
//

import SwiftUI
import KeyboardShortcuts

struct MenuView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var menuVM: MenuViewModel
    
    @Binding var isSummary: Bool
    
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
                Text("\(menuVM.runningStatus)")
                    .padding(EdgeInsets(top:0, leading: 0, bottom: 0, trailing: 0))
                    .italic()
                    .foregroundColor(Color(NSColor.labelColor))
                    .font(.system(size: 12))
                Spacer()
                if menuVM.transcription.recordingState == RecordingStates.recording {
                    recordingAnimation()
                }
                if menuVM.transcription.recordingState == RecordingStates.transcribing {
                    transcriptionAnimation()
                }
                if menuVM.transcription.recordingState == RecordingStates.transforming {
                    transformationAnimation()
                }
            }
            
            
            Divider()
            
            if !isSummary {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        menuVM.activeMode = .transcription
                        menuVM.startRecording()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Begin Transcription", shortcut: KeyboardShortcuts.Name.toggleRecordMode.shortcut?.description))
                    .disabled(menuVM.transcription.recordingState != RecordingStates.stopped || menuVM.isKeyDown)

                    if menuVM.settings.enableOpenAI {
                        Button(action: {
                            menuVM.activeMode = .instruction
                            menuVM.startRecording()
                        }, label: {})
                        .buttonStyle(MenuStyle(title: "Begin Instructive", shortcut: KeyboardShortcuts.Name.toggleInstructionMode.shortcut?.description))
                        .disabled(menuVM.transcription.recordingState != RecordingStates.stopped || menuVM.isKeyDown || !menuVM.settings.enableOpenAI)
                        
                        Button(action: {
                            menuVM.activeMode = .creative
                            menuVM.startRecording()
                        }, label: {})
                        .buttonStyle(MenuStyle(title: "Begin Creative", shortcut: KeyboardShortcuts.Name.toggleCreativeMode.shortcut?.description))
                        .disabled(menuVM.transcription.recordingState != RecordingStates.stopped || menuVM.isKeyDown || !menuVM.settings.enableOpenAI)
                    }
                    
                    Button(action: {
                        Task(priority: .userInitiated) {
                            await menuVM.stopRecording()
                        }
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Complete"))
                    .disabled(menuVM.transcription.recordingState != RecordingStates.recording || menuVM.isKeyDown)
                    
                    Button(action: {
                        menuVM.cancelRecording()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Cancel"))
                    .disabled(menuVM.transcription.recordingState != RecordingStates.recording || menuVM.isKeyDown)
                }
                
                
                Divider()
                
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "history")
                        menuVM.hideMenu()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "History"))
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "settings")
                        menuVM.hideMenu()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Settings"))
                    
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "about")
                        menuVM.hideMenu()
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
                    menuVM.isMenuSummary = false
                }, label: {})
                .buttonStyle(MenuStyle(title: "Reveal Options"))
                
            }
            
            
        }.padding(EdgeInsets(top:0, leading: 5, bottom: 5, trailing: 10))
    }
    
    @State private var isTranscribing = false
    
    private func transcriptionAnimation() -> some View {
        VStack (alignment: .center, spacing: 1) {
            rod(width: 6, height: 4, duration: 1.0)
            rod(width: 8, height: 4, duration: 0.8)
            rod(width: 7, height: 4, duration: 1.2)
        }
        .frame(width:26)
        .onAppear() {
            self.isTranscribing = true
        }
        .onDisappear() {
            self.isTranscribing = false
        }
    }
    
    private func transformationAnimation() -> some View {
        VStack (alignment: .center, spacing: 1) {
            rod(width: 12, height: 2, duration: 1.0)
            rod(width: 12, height: 2, duration: 0.8)
            rod(width: 12, height: 2, duration: 0.6)
            rod(width: 12, height: 2, duration: 0.7)
            rod(width: 12, height: 2, duration: 1.2)
        }
        .frame(width:26)
        .onAppear() {
            self.isTranscribing = true
        }
        .onDisappear() {
            self.isTranscribing = false
        }
    }
    
    
    private func rod(width: CGFloat = 8, height: CGFloat = 4, duration: CGFloat = 1) -> some View {
        let frameWidth: CGFloat = 26
        let offsetWidth: CGFloat = (frameWidth - width) / 2
        return ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color("AnimationBackground"))
                .frame(width: frameWidth, height: height)
            
            RoundedRectangle(cornerRadius: 3)
                .fill(Color("AnimationForeground"))
                .frame(width: width, height: height)
                .offset(x: isTranscribing ? offsetWidth : (-1 * offsetWidth), y: 0)
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
            .fill(Color("AnimationForeground"))
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
    let buttonShortcut: String
    let buttonIcon: Image?
    
    init(title: String, icon: Image? = nil) {
        self.buttonTitle = title
        self.buttonIcon = icon
        self.buttonShortcut = ""
    }

    init(title: String, shortcut: String?, icon: Image? = nil) {
        self.buttonTitle = title
        self.buttonIcon = nil
        self.buttonShortcut = shortcut ?? ""
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            Spacer().frame(width:10)
            if buttonIcon != nil {
                buttonIcon
                    .foregroundColor(isEnabled ? isHovered ? Color(NSColor.selectedMenuItemTextColor) : Color(NSColor.labelColor): Color(NSColor.disabledControlTextColor))
            }
            Text(buttonTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(isEnabled ? isHovered ? Color(NSColor.selectedMenuItemTextColor) : Color(NSColor.labelColor) : Color(NSColor.disabledControlTextColor))
            if buttonShortcut != "" {
                Text(buttonShortcut)
                    .frame(width: 50, alignment: .trailing)
                    .foregroundColor(isEnabled ? isHovered ? Color(NSColor.selectedMenuItemTextColor) : Color(NSColor.disabledControlTextColor) : Color(NSColor.disabledControlTextColor))
            }
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


