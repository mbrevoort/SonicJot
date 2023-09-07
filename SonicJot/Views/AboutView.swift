//
//  About.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/13/23.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top){
                Text("👋")
                Text("SonicJot is fun little utility I built for myself because I can talk a lot faster than I can type. I'm not sure what I'll do with it yet. For now though, thanks for trying it.  Please share any feedback to mike@brevoort.com. \n- Mike Brevoort").italic()
                Spacer()
            }.padding()
        }.frame(width: 400, height: 150)
    }
}

