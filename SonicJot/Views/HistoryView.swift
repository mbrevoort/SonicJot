//
//  HistoryScreen.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/11/23.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State var hover: Bool = false

    
    var body: some View {
        Spacer()
        Text("Up to \(settingsVM.settings.history.size) most recent events").italic()
        List {
            ForEach(settingsVM.settings.history.list()) { item in
                VStack {
                    Spacer()
                    HStack(alignment: .top){
                        Image(systemName: item.type == HistoryItemType.error ? "x.circle" : "waveform")
                        
                        VStack(alignment: .leading) {
                            Text("\(item.friendlyType) - \(item.time.formatted()) \(item.duration > 0 ? String(format: " %.2fs", item.duration) : "")")
                            Text(item.body).textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "square.on.square")
                            .frame(width: 15, alignment: .trailing)
                            .background(Color(NSColor.controlBackgroundColor))
                            .onTapGesture {
                                Clipboard.copy(item.body)
                            }
                            .onHover { isHovered in
                                self.handleHover(isHovered)
                            }
                            .help("copy")

                        Image(systemName: "trash")
                            .frame(width: 15, alignment: .trailing)
                            .background(Color(NSColor.controlBackgroundColor))
                            .onTapGesture {
                                settingsVM.settings.history.delete(item)
                            }
                            .onHover { isHovered in
                                self.handleHover(isHovered)
                            }
                            .help("delete")
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                    Spacer()
                }
                .background(Color(NSColor.controlBackgroundColor))
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
        HistoryView()
    }
}

