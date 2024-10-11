//
//  InitialSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 10/12/24.
//

import SwiftUI

struct InitialSettingsView: View {
    var body: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "gear")
                Text("시스템 설정 이동")
            }
        }
    }
}

#Preview {
    InitialSettingsView()
}
