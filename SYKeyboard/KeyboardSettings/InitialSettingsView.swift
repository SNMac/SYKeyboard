//
//  InitialSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 10/12/24.
//

import SwiftUI

struct InitialSettingsView: View {
    @State private var itemSize = CGSize.zero
    
    var body: some View {
        Button {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        } label: {
            HStack {
                Image(systemName: "gear")
                    .background(GeometryReader {
                        Color.clear.preference(key: ItemSize.self,
                                               value: $0.frame(in: .local).size)
                    })
                    .frame(width: itemSize.width, height: itemSize.height)
                    .onPreferenceChange(ItemSize.self) {
                        itemSize = $0
                    }
                Text("시스템 설정 이동")
            }
        }
    }
}

#Preview {
    InitialSettingsView()
}
