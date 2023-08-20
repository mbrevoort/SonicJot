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
    @State private var isTranscribing = false
    @State private var isRecording = false

    @State private var isHistoryHovered = false
    @State private var isSettingsHovered = false
    @State private var isAboutHovered = false
    @State private var isQuitHovered = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Spacer().frame(height: 5)
            
            if !isSummary {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        currentState.startRecording()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Start"))
                    .disabled(currentState.recordingState != RecordingStates.stopped || currentState.isKeyDown)
                    
                    Button(action: {
                        currentState.stopRecording(autoPaste: false)
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
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "History"))
                    
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "settings")
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Settings"))
                    
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "about")
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "About"))
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Quit"))
                }
                Divider()
                
            } else {
                Button(action: {
                    self.isSummary = false
                }, label: {})
                .buttonStyle(MenuStyle(title: "Reveal Options"))
                
            }
            
            
            HStack {
                Spacer().frame(width:10)
                Image(systemName: "info.circle")
                Text("\(currentState.runningStatus)")
                    .padding(EdgeInsets(top:0, leading: 0, bottom: 0, trailing: 0))
                    .italic()
                    .foregroundColor(Color(white:0.3))
                    .font(.system(size: 12))
                Spacer()
            }

            if !currentState.history.isEmpty {
                let entry = currentState.history.list()[0]
                HStack {
                    Image(systemName: "clock")
                        .padding(EdgeInsets(top:0, leading: 10, bottom: 0, trailing: 0))
                    Text(entry.body)
                        .truncationMode(.tail)
                        .italic()
                        .foregroundColor(Color(white:0.3))
                        .font(.system(size: 12))
                        .frame(height: 20)
                }
            } else {
                Spacer().frame(height: 17)
            }

            if currentState.recordingState == RecordingStates.working {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.gray, lineWidth: 3)
                        .frame(width: 265, height: 3)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 30, height: 3)
                        .offset(x: isTranscribing ? 110 : -110, y: 0)
                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isTranscribing)
                }
                .onAppear() {
                    self.isTranscribing = true
                }
                .onDisappear() {
                    self.isTranscribing = false
                }
                .padding(EdgeInsets(top:5, leading: 10, bottom: 17, trailing: 0))
                
            }

            if currentState.recordingState == RecordingStates.recording {
                HStack(alignment: .center) {
                    
                    Group {
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                    }
                    Group {
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                    }
                    Group {
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                        recAnimationItem()
                    }

                }
                .onAppear() {
                    self.isRecording = true
                }
                .onDisappear() {
                    self.isRecording = false
                }
                .padding(EdgeInsets(top:5, leading: 10, bottom: 17, trailing: 0))
                
            }

            
        }.padding(EdgeInsets(top:0, leading: 5, bottom: 5, trailing: 10))
    }
    
    private func recAnimationItem() -> some View {
        let heightA = Int.random(in: 3..<6)
        let heightB = Int.random(in: 12..<18)
        let duration = Double.random(in: 0.4..<0.9)
        return RoundedRectangle(cornerRadius: 3)
            .stroke(Color.blue, lineWidth: 3)
            .frame(width: 3, height: CGFloat(self.isRecording ? heightA : heightB))
            .animation(Animation.linear(duration: duration).repeatForever(autoreverses: true), value: isRecording)
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
                    .foregroundColor(isEnabled ? isHovered ? Color(white: 0.97) : Color.black : Color.gray)
            }
            Text(buttonTitle)
                .foregroundColor(isEnabled ? isHovered ? Color(white: 0.97) : Color.black : Color.gray)
            Spacer()
            
        }
        .frame(maxWidth:.infinity, minHeight: 25)
        .background(isEnabled ? isHovered ? Color.blue : Color.clear : Color.clear)
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


