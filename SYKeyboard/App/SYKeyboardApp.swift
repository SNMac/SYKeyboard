//
//  SYKeyboardApp.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import AdSupport
import AppTrackingTransparency
import OSLog
import GoogleMobileAds
import FirebaseCore
import FirebaseAnalytics
import FBAudienceNetwork

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "AppDelegate")
        
        // 앱 추적 권한 요청
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:  // 허용됨
                    let idfa: String = "\(ASIdentifierManager.shared().advertisingIdentifier)"
                    os_log("Tracking Authorized, IDFA = %{private}@", log: log, type: .debug, idfa)
                case .denied:  // 거부됨
                    os_log("Tracking Denied", log: log, type: .debug)
                case .notDetermined:  // 결정되지 않음
                    os_log("Tracking Not Determined", log: log, type: .debug)
                case .restricted:  // 제한됨
                    os_log("Tracking Restricted", log: log, type: .debug)
                @unknown default:  // 알려지지 않음
                    os_log("Tracking Unknown", log: log, type: .debug)
                }
            }
        }
        
        // Use Firebase library to configure APIs.
        FirebaseApp.configure()
        
        // Pass user's consent after acquiring it.
        FBAdSettings.setAdvertiserTrackingEnabled(true)
        
        // Initialize the Google Mobile Ads SDK.
        let ads = MobileAds.shared
        ads.start { status in
            // Optional: Log each adapter's initialization latency.
            let adapterStatuses = status.adapterStatusesByClassName
            for adapter in adapterStatuses {
                let adapterStatus = adapter.value
                os_log("Adapter Name: %@, Description: %@, Latency: %f", log: log, type: .debug, adapter.key,
                       adapterStatus.description, adapterStatus.latency)
            }
            
            // Start loading ads here...
            
        }
        
        return true
    }
}

@main
struct SYKeyboardApp: App {
    // To handle app delegate callbacks in an app that uses the SwiftUI lifecycle,
    // you must create an application delegate and attach it to your `App` struct
    // using `UIApplicationDelegateAdaptor`.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
        }
    }
}
