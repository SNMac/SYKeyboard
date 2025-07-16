//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    @AppStorage(UserDefaultsKeys.isOnboarding, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) private var isOnboarding = DefaultValues.isOnboarding
    @State private var isAdReceived: Bool = false
    
    private var state: PreviewKeyboardState
    
    init() {
        UserDefaultsManager.shared.setupUserDefaults()
        
        state = PreviewKeyboardState()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: geometry.size.width)
            NavigationStack {
                KeyboardTestView()
                
                KeyboardSettingsView()
                
                if isAdReceived {
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(width: geometry.size.width, height: adSize.size.height)
                    }
                }
                
            }
            .overlay(alignment: .bottom, content: {
                BannerViewContainer(adSize, isAdReceived: $isAdReceived)
                    .frame(height: isAdReceived ? adSize.size.height : 0)
            })
            .environmentObject(state)
            .sheet(isPresented: $isOnboarding) {
                InstructionsTabView()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.8)])
            }
        }
    }
}

#Preview {
    ContentView()
}
