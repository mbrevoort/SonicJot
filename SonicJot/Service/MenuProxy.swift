//
//  MenuProxy.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/2/24.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@DependencyClient
struct MenuProxyClient {
    var open: () -> Void
    var close: () -> Void
    var isOpen: () -> Bool = { false }
    var replaceIcon: (RecordingStateIcon) -> Void
    
    // TODO: Reevaluate: I haven't figured out a better way to reference AppDelegate, using NSApplication.shared.delegate never worked.
    var setAppDelegate: (AppDelegate) -> Void
    
    enum RecordingStateIcon: String {
        case recording = "waveform.circle.fill"
        case transcribing = "hourglass.circle"
        case transforming = "function"
        case stopped = "waveform"
        case initializing = "waveform.slash"
    }
}

extension DependencyValues {
    var menuProxy: MenuProxyClient {
        get { self[MenuProxyClient.self] }
        set { self[MenuProxyClient.self] = newValue}
    }
}

extension MenuProxyClient: DependencyKey {
    static var liveValue: Self {
        var appDelegate: AppDelegate?
        
        return Self(
            open: {
                guard appDelegate != nil else {
                    return
                }
                DispatchQueue.main.async {
                    appDelegate?.openPopover()
                }
            },
            close: {
                guard appDelegate != nil else {
                    return
                }
                DispatchQueue.main.async {
                        appDelegate?.closePopover()
                }
            },
            isOpen: {
                guard appDelegate != nil else {
                    return false
                }
                return appDelegate!.isPopoverOpen()
            },
            replaceIcon: { systemSymbolName in
                guard appDelegate != nil else {
                    return
                }
                appDelegate?.updateMenuIcon(systemSymbolName)
            },
            setAppDelegate: { appDelegateRef in
                appDelegate = appDelegateRef
            }
        )
    }
}

extension MenuProxyClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        open: {},
        close: {},
        isOpen: { true },
        replaceIcon: { systemSymbolName in
            return
        },
        setAppDelegate: { _ in }
    )
    
    static let noop = Self(
        open: { },
        close: {  },
        isOpen: { false },
        replaceIcon: { _ in  },
        setAppDelegate: { _ in}
    )
}

