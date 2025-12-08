//
//  SYKeyboardApp.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import AppTrackingTransparency
import OSLog

import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics
import GoogleMobileAds

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    var window: UIWindow?  // FBAudienceNetwork 크래시 방지
    
    // MARK: - didFinishLaunchingWithOptions
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase 로딩
        FirebaseApp.configure()
        
        // IDFV를 사용하여 Analytics, Crashlytics User ID 설정
        let idfv = UIDevice.current.identifierForVendor?.uuidString
        Analytics.setUserID(idfv)
        Crashlytics.crashlytics().setUserID(idfv)
        
        // AdMob 로딩
        Task {
            let initializationStatus = await MobileAds.shared.start()
            for (adapterName, status) in initializationStatus.adapterStatusesByClassName {
                logger.debug("Adapter: \(adapterName), Description: \(status.description), Latency: \(status.latency)")
            }
        }
        
        return true
    }
}

// MARK: - SYKeyboardApp

@main
struct SYKeyboardApp: App {
    
    // MARK: - Properties
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.openURL) var openURL
    
    // MARK: - Contents
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settingsURL)
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
