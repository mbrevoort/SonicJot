//
//  CheckForUpdates.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/18/24.
//

import Combine
import SwiftUI
import Foundation
import ComposableArchitecture
import Sparkle

public struct CheckForUpdatesReducer: Reducer {
    // MARK: - State
    @ObservableState
    public struct State: Equatable {
        var updater: SPUUpdater? = nil
    }
    
    // MARK: - Action
    public enum Action {
        case initialize
        case setUpdater(SPUUpdater)
        case checkForUpdatesClicked
    }
    
    // MARK: - Reducer
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .initialize:
                return .run { send in
                    let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
                    await send(.setUpdater(controller.updater))
                }
            case let .setUpdater(updater):
                state.updater = updater
                return .none
            case .checkForUpdatesClicked:
                guard state.updater != nil else {
                    return .none
                }
                return .run { [updater = state.updater] send in
                    updater!.checkForUpdates()
                }
            }
        }
    }
}

struct CheckForUpdatesView: View {
    let store: StoreOf<CheckForUpdatesReducer>
    
    init(store: StoreOf<CheckForUpdatesReducer>) {
        self.store = store
        store.send(.initialize)
    }
    
    
    var body: some View {
        Button(action: {
            store.send(.checkForUpdatesClicked)
        }, label: {})
    }
}

#Preview {
    CheckForUpdatesView(
        store: Store(initialState: CheckForUpdatesReducer.State()) {
            CheckForUpdatesReducer()
                ._printChanges()
        }
    )
}

