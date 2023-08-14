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
        Spacer()
        Text("👋 History cleared on restart").italic()
        List {
            ForEach(currentState.history.list()) { item in
                VStack {
                    Spacer()
                    HStack(alignment: .top){
                        Image(systemName: item.type == HistoryItemType.error ? "x.circle" : "waveform")
                        VStack(alignment: .leading) {
                            Text("\(item.friendlyType) - \(item.time.formatted())")
                            Text(item.body).textSelection(.enabled)
                        }
                    }
                    .listRowBackground(Color(white: 0.9).clipped().cornerRadius(10))
                    Spacer()
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

