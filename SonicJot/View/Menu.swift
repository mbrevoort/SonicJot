//
//  Menu.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/2/24.
//
import SwiftUI
import KeyboardShortcuts
import ComposableArchitecture

enum RecordingState {
    case recording
    case transcribing
    case transforming
    case stopped
    case initializing
}

// Keyboard shortcut registration
extension KeyboardShortcuts.Name {
    static let toggleRecordMode = Self("toggleRecordMode", default: .init(.x, modifiers: [.control, .command]))
}

@Reducer
public struct MenuReducer: Reducer {
    @Dependency(\.transcription) var transcription
    @Dependency(\.recording) var recording
    @Dependency(\.clipboard) var clipboard
    @Dependency(\.settings) var settings
    @Dependency(\.sound) var sound
    @Dependency(\.menuProxy) var menuProxy
    
    // MARK: - State
    @ObservableState
    public struct State: Equatable {
        var recordingState: RecordingState = .initializing
        var isSummary = false
        var lastActivity: LastActivity?
    }
    
    // MARK: - Action
    public enum Action {
        case beginTranscriptionClicked
        case cancelTranscriptionClicked
        case completeTranscriptionClicked
        case transcriptionServiceReady
        case initialize
        case startTranscription(URL)
        case completeTransription(TranscriptionResult)
        case transcriptionError(String)
        case shortcutKeyDown
        case shortcutKeyUp
        case showMoreClicked
        case showSummary
    }
    
    // MARK: - Reducer
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .beginTranscriptionClicked:
                guard state.recordingState != .recording else {
                    return .none
                }
                
                state.recordingState = .recording
                state.lastActivity = nil
                return .run { send in
                    try await recording.start()
                    menuProxy.replaceIcon(.recording)
                    if try settings.get().enableSounds {
                        sound.playStart()
                    }
                }
                
            case .cancelTranscriptionClicked:
                guard state.recordingState == .recording else {
                    return .none
                }
                
                state.recordingState = .stopped
                return .run { send in
                    menuProxy.replaceIcon(.stopped)
                    _ = try await recording.stop()
                }
                
            case .completeTranscriptionClicked:
                guard state.recordingState == .recording else {
                    return .none
                }
                
                state.recordingState = .transcribing
                return .run { send in
                    let url = try await recording.stop()
                    await send(.startTranscription(url as URL))
                    if try settings.get().enableSounds {
                        sound.playStop()
                    }
                }
                
            case let .startTranscription(url):
                return .run { send in
                    do {
                        menuProxy.replaceIcon(.transcribing)
                        let result = try await transcription.transcribe(url)
                        await send(.completeTransription(result))
                        
                    } catch {
                        // TODO: error in history
                        if try settings.get().enableSounds {
                            sound.playError()
                        }
                        await send(.transcriptionError(error.localizedDescription))
                    }
                }
                
            case let .completeTransription(result):
                menuProxy.close()
                state.recordingState = .stopped
                state.isSummary = false
                state.lastActivity = LastActivity(transcriptionResult: result)
                return .run { send in
                    menuProxy.replaceIcon(.stopped)
                    let currentSettings = try settings.get()
                    if currentSettings.enableSounds {
                        sound.playStop()
                    }
                    clipboard.copy(result.text)
                    
                    if currentSettings.enableAutoPaste {
                        clipboard.paste()
                    }
                }
                
            case let .transcriptionError(error):
                state.lastActivity = LastActivity(error: error, date: settings.now())
                return .run { send in
                    await send(.transcriptionServiceReady)
                }
                
            case .transcriptionServiceReady:
                state.recordingState = .stopped
                return .run { send in
                    menuProxy.replaceIcon(.stopped)
                }
                
            case .initialize:
                return .run { send in
                    menuProxy.replaceIcon(.initializing)
                    try await transcription.initialize()
                    await send(.transcriptionServiceReady)
                }
                
            case .shortcutKeyDown:
                guard state.recordingState != .initializing else {
                    return .none
                }
                return .run { send in
                    if !menuProxy.isOpen() {
                        menuProxy.open()
                        await send(.showSummary)
                    }
                    await send(.beginTranscriptionClicked)
                }
                
            case .shortcutKeyUp:
                guard state.recordingState != .initializing else {
                    return .none
                }
                return .run { send in
                    await send(.completeTranscriptionClicked)
                }
                
            case .showMoreClicked:
                state.isSummary = false
                return .none
                
            case .showSummary:
                state.isSummary = true
                return .none
            }
            
        }
    }
    
    struct LastActivity: Equatable {
        var isError: Bool = false
        var text: String
        var date: Date = Date()
        var words: Int = 0
        var duration: Double = 0.0
        
        init(transcriptionResult: TranscriptionResult) {
            self.text = transcriptionResult.text
            self.words = transcriptionResult.words
            self.duration = transcriptionResult.duration
            self.date = transcriptionResult.date
        }
        
        init(error: String) {
            self.isError = true
            self.text = error
        }
        
        init(error: String, date: Date) {
            self.isError = true
            self.text = error
            self.date = date
        }
    }
}

struct MenuView: View {
    @Bindable var store: StoreOf<MenuReducer>
    
    @Environment(\.openWindow) private var openWindow
    //    @EnvironmentObject var menuVM: MenuViewModel
    
    @State private var isHistoryHovered = false
    @State private var isSettingsHovered = false
    @State private var isAboutHovered = false
    @State private var isQuitHovered = false
    
    public init(store: StoreOf<MenuReducer>) {
        self.store = store
        store.send(.initialize)
        
        KeyboardShortcuts.onKeyDown(for: .toggleRecordMode) {
            print("DOWN")
            store.send(.shortcutKeyDown)
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleRecordMode) {
            print("UP")
            store.send(.shortcutKeyUp)
        }
    }
    
    func getStatus(_ state: RecordingState) -> String {
        switch state {
        case RecordingState.initializing:
            return "Downloading and preparing models..."
        case RecordingState.stopped:
            return "Ready..."
        case RecordingState.recording:
            return "Recording..."
        case RecordingState.transcribing:
            return "Transcribing..."
        case RecordingState.transforming:
            return "Transforming..."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer().frame(height: 10)
            
            HStack {
                Spacer().frame(width:10)
                Image(systemName: "info.circle")
                Text(self.getStatus(store.recordingState))
                    .padding(EdgeInsets(top:0, leading: 0, bottom: 0, trailing: 0))
                    .italic()
                    .foregroundColor(Color(NSColor.labelColor))
                    .font(.system(size: 12))
                Spacer()
                MenuAnimation(recordingState: store.recordingState)
            }
            Spacer().frame(height: 10)
            
            Divider()
            
            if store.isSummary {
                Button(action: {
                    store.send(.showMoreClicked)
                }, label: {})
                .buttonStyle(MenuStyle(title: "More..."))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        store.send(.beginTranscriptionClicked)
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Begin Transcription", shortcut: KeyboardShortcuts.Name.toggleRecordMode.shortcut?.description))
                    .disabled(store.recordingState != .stopped)
                    
                    
                    Button(action: {
                        store.send(.completeTranscriptionClicked)
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Complete"))
                    .disabled(store.recordingState != .recording)
                    
                    Button(action: {
                        store.send(.cancelTranscriptionClicked)
                        //                            menuVM.cancelRecording()
                    }, label: {})
                    .buttonStyle(MenuStyle(title: "Cancel"))
                    .disabled(store.recordingState != .recording)
                }
                
                if (store.lastActivity != nil && store.lastActivity!.isError) {
                    Divider()
                    LastActivityStatus(icon: "x.circle", iconColor: .red, text: store.lastActivity!.text)
                }
                
                Divider()
                
                SettingsLink().buttonStyle(MenuStyle(title: "Settings"))
                
                Divider()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }, label: {})
                .buttonStyle(MenuStyle(title: "Quit"))
            }
            
            
        }
        .padding(EdgeInsets(top:0, leading: 5, bottom: 5, trailing: 5))
        .frame(maxWidth: 400, idealHeight: 100)
        
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

struct LastActivityStatus: View {
    var icon: String?
    var iconColor: Color?
    var text: String = ""
    
    var body: some View {
        VStack {
        HStack(alignment: .top) {
            if (self.icon != nil && self.iconColor != nil) {
                Image(systemName: self.icon!)
                    .imageScale(.medium)
                    .foregroundColor(self.iconColor!)
                    .padding(.leading, 10)
                    .padding(.bottom, 5)
            }
            Text(self.text)
                .fontWeight(.light)
                .font(Font.system(.footnote, design: .monospaced))
                .padding(.trailing, 5)
                .padding(.bottom, 10)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(.vertical)
    }
    }
}

struct MenuAnimation: View {
    var recordingState: RecordingState
    
    var body: some View {
        if recordingState == .recording {
            recordingAnimation()
        } else if recordingState == .transcribing {
            transcriptionAnimation()
        } else {
            EmptyView()
        }
    }
    
    @State private var isTranscribingAnimation = false
    
    private func transcriptionAnimation() -> some View {
        VStack (alignment: .center, spacing: 1) {
            rod(width: 6, height: 4, duration: 1.0)
            rod(width: 8, height: 4, duration: 0.8)
            rod(width: 7, height: 4, duration: 1.2)
        }
        .frame(width:26)
        .onAppear() {
            self.isTranscribingAnimation = true
        }
        .onDisappear() {
            self.isTranscribingAnimation = false
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
                .offset(x: isTranscribingAnimation ? offsetWidth : (-1 * offsetWidth), y: 0)
                .animation(Animation.linear(duration: duration).repeatForever(autoreverses: true), value: isTranscribingAnimation)
        }
    }
    
    @State private var isRecordingAnimation = false
    
    private func recordingAnimation() -> some View {
        HStack(alignment: .center, spacing: 1) {
            bar(low:0.4)
                .animation(animateBar.speed(1.5), value: isRecordingAnimation)
            bar(low:0.3)
                .animation(animateBar.speed(1.2), value: isRecordingAnimation)
            bar(low:0.4)
                .animation(animateBar.speed(1.0), value: isRecordingAnimation)
            bar(low:0.5)
                .animation(animateBar.speed(1.5), value: isRecordingAnimation)
            bar(low:0.3)
                .animation(animateBar.speed(1.7), value: isRecordingAnimation)
            bar(low:0.5)
                .animation(animateBar.speed(1.0), value: isRecordingAnimation)
        }
        .frame(width: 26)
        .onAppear() {
            self.isRecordingAnimation = true
        }
        .onDisappear() {
            self.isRecordingAnimation = false
        }
    }
    
    private func bar(low: CGFloat = 0.0, high: CGFloat = 1.0) -> some View {
        return RoundedRectangle(cornerRadius: 3)
            .fill(Color("AnimationForeground"))
            .frame(width: 2, height: (isRecordingAnimation ? high : low) * 16)
            .frame(height: 16)
    }
    
    var animateBar: Animation {
        return .linear(duration:0.5).repeatForever()
    }
}


#Preview {
    MenuView(
        store: Store(initialState: MenuReducer.State()) {
            MenuReducer()
                ._printChanges()
        }
    )
}
