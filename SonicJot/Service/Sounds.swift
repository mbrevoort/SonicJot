//
//  Sounds.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/2/24.
//

import Cocoa
import ComposableArchitecture

@DependencyClient
struct SoundClient {
    var playError: () -> Void
    var playStart: () -> Void
    var playStop: () -> Void
    var playDone: () -> Void
}

extension DependencyValues {
    var sound: SoundClient {
        get { self[SoundClient.self] }
        set { self[SoundClient.self] = newValue}
    }
}

extension SoundClient: DependencyKey {
    static var liveValue: Self {

        // create new instances to allow them to play simultaneously
        return Self(
            playError: {
                let errorSound = NSSound(named: "error.mp3")
                errorSound?.play()
            },
            playStart: {
                let startSound = NSSound(named: "boop1.mp3")
                startSound?.volume = 0.05
                startSound?.play()
            },
            playStop: {
                let stopSound = NSSound(named: "boop2.mp3")
                stopSound?.volume = 0.05
                stopSound?.play()
            },
            playDone: {
                let pingSound = NSSound(named: "ping.mp3")
                pingSound?.volume = 0.05
                pingSound?.play()
            }
        )
    }
}

extension SoundClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        playError: { },
        playStart: { },
        playStop: { },
        playDone: { }
    )
    
    static let noop = Self(
        playError: { },
        playStart: { },
        playStop: { },
        playDone: { }
    )
}
