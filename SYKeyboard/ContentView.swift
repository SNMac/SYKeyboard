//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    private var defaults: UserDefaults?
    private var state: PreviewNaratgeulState
    
    init() {
        defaults = UserDefaults(suiteName: GlobalValues.groupBundleID)
        GlobalValues.setupDefaults(defaults)
        
        state = PreviewNaratgeulState()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)
            
            NavigationStack {
                KeyboardTestView()
                
                KeyboardSettingsView()
                
                BannerAdView(adSize)
                  .frame(height: adSize.size.height)
            }
            .environmentObject(state)
        }
    }
}

#Preview {
    ContentView()
}
