//
//  HistoryScreen.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/11/23.
//

import SwiftUI

struct HistoryScreen: View {
    @ObservedObject var currentState: AppState = AppState.instance()
    var body: some View {
       List {
            ForEach(currentState.history.list()) { item in
                Text(item.description).textSelection(.enabled)
                if item.description != currentState.history.list().last?.description {
                   Divider()
                }
            }
        }
    }
}

struct HistoryScreen_Previews: PreviewProvider {
    static var previews: some View {
        HistoryScreen()
    }
}
 
