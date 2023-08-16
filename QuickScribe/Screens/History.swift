//
//  HistoryScreen.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/11/23.
//

import SwiftUI

struct HistoryScreen: View {
    @ObservedObject var currentState: AppState = AppState.instance()
    @State var hover: Bool = false
    
    var body: some View {
        Spacer()
        Text("Up to \(currentState.history.size) most recent events").italic()
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
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "square.on.square")
                            .frame(width: 15, alignment: .trailing)
                            .background(Color(white: 0.97))
                            .onTapGesture {
                                AppState.setClipboard(item.body)
                            }
                            .onHover { isHovered in
                                self.handleHover(isHovered)
                            }
                            .help("copy")

                        Image(systemName: "trash")
                            .frame(width: 15, alignment: .trailing)
                            .background(Color(white: 0.97))
                            .onTapGesture {
                                currentState.history.delete(item)
                            }
                            .onHover { isHovered in
                                self.handleHover(isHovered)
                            }
                            .help("delete")
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                    Spacer()
                }
                .background(Color(white: 0.97))
                .cornerRadius(5)
            }
        }
    }
    
    func handleHover(_ isHovered: Bool) {
        self.hover = isHovered
        DispatchQueue.main.async {
            if (self.hover) {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }

    }
}

struct HistoryScreen_Previews: PreviewProvider {
    static var previews: some View {
        HistoryScreen()
    }
}

