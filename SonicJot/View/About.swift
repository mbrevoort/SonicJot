//
//  About.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/2/24.
//

import Combine
import SwiftUI
import Foundation
import ComposableArchitecture

public struct AboutReducer: Reducer {
    // MARK: - State
    @ObservableState
    public struct State: Equatable {
        var version: String = "unknown"
        var build: String = "unknown"
    }
    
    // MARK: - Action
    public enum Action {
        case initialize
    }
    
    // MARK: - Reducer
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .initialize:
                state.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                state.build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
                return .none
            }
        }
    }
}

struct AboutView: View {
    let store: StoreOf<AboutReducer>
    
    init(store: StoreOf<AboutReducer>) {
        self.store = store
        store.send(.initialize)
    }
    
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
            Spacer()
            Text("SonicJot").font(.title)
            Text("Version \(store.version) (\(store.build))")
            Text("[Open Source on Github](https://github.com/mbrevoort/SonicJot)")
                .padding(.bottom)
            Text("Made in Denver, Colorado")
            Text("[Mike Brevoort](https://mikebrevoort.com)")
            Spacer()
        }
    }
}

#Preview {
    AboutView(
        store: Store(initialState: AboutReducer.State()) {
            AboutReducer()
                ._printChanges()
        }
    )
}
