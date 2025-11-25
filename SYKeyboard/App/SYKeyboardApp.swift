//
//  SYKeyboardApp.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import AppTrackingTransparency

import FBAudienceNetwork
import FirebaseAnalytics
import FirebaseCore
import GoogleMobileAds

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FBAdSettings.setAdvertiserTrackingEnabled(true)
        
        FirebaseApp.configure()
        MobileAds.shared.start()
        
        return true
    }
}

@main
struct SYKeyboardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                        Task { await ATTrackingManager.requestTrackingAuthorization() }
                    }
                }
        }
    }
}
