//
//  About.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/13/23.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .center) {
            Text("SonicJot").font(.title)
            Version()
            Spacer()
            Text("Handcrafted in Denver, Colorado\nMike Brevoort (mike@brevoort.com).")
            Spacer()
        }.frame(width: 400, height: 150)
    }
    
    func Version() -> Text {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return Text("Version \(appVersion) (\(build))")
    }
    
    
}
