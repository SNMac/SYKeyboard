//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                KeyboardTestView()
                QuickSettingsView()
            }
            .padding()
        }
        .navigationTitle("SYKeyboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
