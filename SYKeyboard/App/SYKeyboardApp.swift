//
//  SYKeyboardApp.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import AppTrackingTransparency
import OSLog

import FBAudienceNetwork
import FirebaseCore
import GoogleMobileAds

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FBAudienceNetworkAds.initialize(with: nil, completionHandler: nil)
        
        FirebaseApp.configure()
        
        Task {
            let initializationStatus = await MobileAds.shared.start()
            for (adapterName, status) in initializationStatus.adapterStatusesByClassName {
                logger.info("Adapter: \(adapterName), Description: \(status.description), Latency: \(status.latency)")
            }
        }
        
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
