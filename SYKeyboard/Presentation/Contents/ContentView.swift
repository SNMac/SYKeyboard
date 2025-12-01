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
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.isOnboarding, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isOnboarding = DefaultValues.isOnboarding
    
    @State private var isAdReceived: Bool = false
    
    // MARK: - Contents
    
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
                        BannerAdView(adSize, isAdReceived: $isAdReceived)
                            .frame(maxWidth: .infinity, maxHeight: adSize.size.height)
                            .background(isAdReceived ? Color(.systemBackground) : .clear, ignoresSafeAreaEdges: .bottom)
                            .opacity(isAdReceived ? 1 : 0)
                            .allowsHitTesting(isAdReceived)
                            .animation(.easeInOut(duration: 1), value: isAdReceived)
                    }
                }
            }
            .onAppear {
                hideKeyboard()
            }
            .navigationTitle(Bundle.displayName ?? "SY키보드")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isOnboarding) {
                InstructionsTabView()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.8)])
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
