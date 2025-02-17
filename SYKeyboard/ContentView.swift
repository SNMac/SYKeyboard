//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    @AppStorage("isOnboarding", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isOnboarding = true
    @State private var isAdReceived: Bool = false
    
    private var defaults: UserDefaults?
    private var state: PreviewKeyboardState
    
    init() {
        defaults = UserDefaults(suiteName: GlobalValues.groupBundleID)
        GlobalValues.setupDefaults(defaults)
        
        state = PreviewKeyboardState()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)
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
                BannerView(adSize, isAdReceived: $isAdReceived)
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
