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
import Firebase

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
                    os_log("Tracking Unknow", log: log, type: .debug)
                }
            }
        }
        
        // Use Firebase library to configure APIs.
        FirebaseApp.configure()
        
        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
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
        }
    }
}
