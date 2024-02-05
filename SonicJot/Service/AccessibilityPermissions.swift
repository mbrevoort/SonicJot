//
//  AccessibilityPermissions.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/2/24.
//

import Cocoa
import ComposableArchitecture

@DependencyClient
struct AccessibilityPermissionsClient {
    var prompt: () -> Void
}

extension DependencyValues {
    var accessibilityPermissions: AccessibilityPermissionsClient {
        get { self[AccessibilityPermissionsClient.self] }
        set { self[AccessibilityPermissionsClient.self] = newValue}
    }
}

extension AccessibilityPermissionsClient: DependencyKey {
    static var liveValue: Self {
        return Self(
            prompt: {
                let accessibilityURL = URL(
                    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                )
                if let url = accessibilityURL {
                    NSWorkspace.shared.open(url)
                }
            }
        )
    }
}

extension AccessibilityPermissionsClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        prompt: { }
    )
    
    static let noop = Self(
        prompt: { }
    )
}
