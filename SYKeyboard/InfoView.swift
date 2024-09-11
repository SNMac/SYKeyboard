//
//  InfoView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/12/24.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        HStack {
            Text("버전")
            Spacer()
            Text((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    InfoView()
}
