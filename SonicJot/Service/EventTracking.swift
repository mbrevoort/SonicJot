//
//  EventTracking.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/22/23.
//

import Foundation
import Mixpanel
import ComposableArchitecture

@DependencyClient
struct EventTrackingClient {
    var transcription: (EventTracking.TranscriptionProvider, Double, Int) -> Void
}

extension DependencyValues {
    var eventTracking: EventTrackingClient {
        get { self[EventTrackingClient.self] }
        set { self[EventTrackingClient.self] = newValue}
    }
}

extension EventTrackingClient: DependencyKey {
    static var liveValue: Self {
        EventTracking.initialize()

        return Self(
            transcription: { provider, duration, numWords in
                EventTracking.transcription(provider: provider.rawValue, duration: duration, numWords: numWords)
            }
        )
    }
}

class EventTracking {
    private static var _instance: EventTracking?
    private static var enabled = false

    enum TranscriptionProvider: String {
        case Local = "local"
        case OpenAI = "openai"
    }

    init(enableLogging: Bool = false) {
        let mixpanelToken = Bundle.main.infoDictionary?["MIXPANEL_PROJECT_TOKEN"] as? String ?? ""

        if mixpanelToken.isEmpty {
            print("MIXPANEL DISABLED becauase MIXPANEL_PROJECT_TOKEN is empty")
            return
        }

        Mixpanel.initialize(token: mixpanelToken)
        Mixpanel.mainInstance().loggingEnabled = enableLogging
        EventTracking.enabled = true

        if let userId = Mixpanel.mainInstance().anonymousId {
            Mixpanel.mainInstance().identify(distinctId: userId);
            Mixpanel.mainInstance().people.set(properties: [ "$name": NSUserName()])
        }
    }

    static func initialize(enableLogging: Bool = false) {
        if _instance == nil {
            _instance = EventTracking(enableLogging: enableLogging)
        }
    }

    static func transcription(provider: String, duration: Double, numWords: Int) {
        if !enabled {
            return
        }

        Mixpanel.mainInstance().track(event: "Transcription", properties: [
            "Provider": provider,
            "Transcription Duration": (duration*100).rounded()/100,
            "Number of Words": numWords,
        ])
    }
}

extension EventTrackingClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        transcription: {_,_,_ in }
    )
    
    static let noop = Self(
        transcription: {_,_,_ in }
    )
}
