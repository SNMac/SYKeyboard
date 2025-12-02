//
//  InitialSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 10/12/24.
//

import SwiftUI

import FirebaseAnalytics

struct InitialSettingsView: View {
    
    // MARK: - Contents

    var body: some View {
        Button {
            Analytics.logEvent("open_system_settings", parameters: [
                "view": "initial_settings"
            ])
            
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        } label: {
            HStack {
                Image(.gear)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("시스템 설정 이동")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    InitialSettingsView()
}
