//
//  EventTracking.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/22/23.
//

import Foundation
import Mixpanel

class EventTracking {
    private static var _instance: EventTracking?
    private static var enabled = false
    
    init(enableLogging: Bool = false) {
        let mixpanelToken = Bundle.main.infoDictionary?["MIXPANEL_PROJECT_TOKEN"] as? String ?? ""
        
        if mixpanelToken.isEmpty {
            print("MIXPANEL DISALBED becauase MIXPANEL_PROJECT_TOKEN is empty")
            return
        }
        
        Mixpanel.initialize(token: mixpanelToken)
        Mixpanel.mainInstance().loggingEnabled = enableLogging
        EventTracking.enabled = true
    }
    
    static func initialize(enableLogging: Bool = false) {
        if _instance == nil {
            _instance = EventTracking(enableLogging: enableLogging)
        }
    }
    
    static func transcription(provider: String, recordingDuration: Double, transcriptionDuration: Double, numWords: Int) {
        if !enabled {
            return
        }
        
        Mixpanel.mainInstance().track(event: "Transcription", properties: [
            "Provider": provider,
            "Recording Duration": (recordingDuration*100).rounded()/100,
            "Transcription Duration": (transcriptionDuration*100).rounded()/100,
            "Number of Words": numWords,
        ])
    }
}

