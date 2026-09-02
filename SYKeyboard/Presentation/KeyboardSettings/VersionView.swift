//
//  VersionView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/3/26.
//

import SwiftUI

import FirebaseAnalytics

struct VersionView: View {
    
    // MARK: - Properties
    
    @State private var isShowingLicenses = false
    
    // MARK: - Content
    
    var body: some View {
        HStack {
            Text("버전")
            
            Spacer()
            
            Text(Bundle.appVersion ?? "Unknown")
                .foregroundStyle(.gray)
        }
        
        Button {
            Analytics.logEvent("open_licenses", parameters: [
                "view": "InfoView",
            ])
            
            isShowingLicenses = true
        } label: {
            HStack {
                Image(systemName: "doc.text")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("오픈소스 라이선스")
            }
        }
        .fullScreenCover(isPresented: $isShowingLicenses) {
            OpenSourceLicenseView()
        }
    }
}

// MARK: - Preview

#Preview {
    VersionView()
}
