//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

import SYKeyboardCore

import GoogleMobileAds

struct ContentView: View {
    @AppStorage(UserDefaultsKeys.isOnboarding, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isOnboarding = DefaultValues.isOnboarding
    
    @State private var isAdReceived: Bool = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let adSize = currentOrientationAnchoredAdaptiveBanner(width: geometry.size.width)
                
                ZStack(alignment: .bottom) {
                    VStack {
                        KeyboardTestView()
                        
                        KeyboardSettingsView()
                    }
                    .safeAreaInset(edge: .bottom) {
                        if isAdReceived {
                            Color.clear
                                .frame(height: adSize.size.height)
                        }
                    }
                    
                    BannerViewContainer(adSize, isAdReceived: $isAdReceived)
                        .frame(maxWidth: .infinity, maxHeight: adSize.size.height)
                        .background(isAdReceived ? Color(uiColor: .systemBackground).edgesIgnoringSafeArea(.bottom) : nil)
                        .opacity(isAdReceived ? 1 : 0)
                        .allowsHitTesting(isAdReceived)
                        .animation(.easeInOut(duration: 1), value: isAdReceived)
                }
            }
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
