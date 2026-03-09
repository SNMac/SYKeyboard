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

import SYKeyboardCore

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    var window: UIWindow?  // FBAudienceNetwork 크래시 방지
    
    // MARK: - didFinishLaunchingWithOptions
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase 로딩
        FirebaseApp.configure()
        
        // IDFV를 사용하여 Analytics, Crashlytics User ID 설정
        let idfv = UIDevice.current.identifierForVendor?.uuidString
        Analytics.setUserID(idfv)
        Crashlytics.crashlytics().setUserID(idfv)
        
        setInitialUserProperties()
        
        // AdMob 로딩
        Task {
            let initializationStatus = await MobileAds.shared.start()
            for (adapterName, status) in initializationStatus.adapterStatusesByClassName {
                logger.debug("Adapter: \(adapterName), Description: \(status.description), Latency: \(status.latency)")
            }
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    /// 앱 실행 시 현재 `UserDefaults`에 저장된 설정값들을 Firebase Analytics User Property로 전송합니다.
    private func setInitialUserProperties() {
        let keyboardSettingsManager = UserDefaultsManager.shared
        
        func setAnalyticsProperty(_ string: String, forName name: String) {
            Analytics.setUserProperty(string, forName: name)
        }
        
        func setAnalyticsProperty(_ bool: Bool, forName name: String) {
            Analytics.setUserProperty(bool ? "true" : "false", forName: name)
        }
        
        func setAnalyticsProperty(_ double: Double, format: String, forName name: String) {
            Analytics.setUserProperty(String(format: format, double), forName: name)
        }
        
        // 한글 키보드
        let selectedHangeulKeyboardRaw = keyboardSettingsManager.selectedHangeulKeyboard.rawValue
        let hangeulKeyboard = HangeulKeyboardSelectView.HangeulKeyboard(rawValue: selectedHangeulKeyboardRaw) ?? .naratgeul
        setAnalyticsProperty(hangeulKeyboard.analyticsValue, forName: "pref_hangeul_keyboard")
        
        // 피드백 설정
        setAnalyticsProperty(keyboardSettingsManager.isSoundFeedbackEnabled, forName: "pref_sound_feedback")
        setAnalyticsProperty(keyboardSettingsManager.isHapticFeedbackEnabled, forName: "pref_haptic_feedback")
        
        // 입력 설정
        let selectedLongPressActionRaw = keyboardSettingsManager.selectedLongPressAction.rawValue
        let longPressMode = InputSettingsView.LongPressMode(rawValue: selectedLongPressActionRaw) ?? .repeatInput
        setAnalyticsProperty(longPressMode.analyticsValue, forName: "pref_long_press_action")
        setAnalyticsProperty(keyboardSettingsManager.longPressDuration, format: "%.2f", forName: "pref_long_press_duration")
        setAnalyticsProperty(keyboardSettingsManager.repeatRate, format: "%.3f", forName: "pref_repeat_rate")
        setAnalyticsProperty(keyboardSettingsManager.isAutoCapitalizationEnabled, forName: "pref_auto_capitalization")
        setAnalyticsProperty(keyboardSettingsManager.isTextReplacementEnabled, forName: "pref_text_replacement")
        setAnalyticsProperty(keyboardSettingsManager.isPeriodShortcutEnabled, forName: "pref_period_shortcut")
        setAnalyticsProperty(keyboardSettingsManager.isAutoChangeToPrimaryEnabled, forName: "pref_auto_change_primary")
        setAnalyticsProperty(keyboardSettingsManager.isDragToMoveCursorEnabled, forName: "pref_drag_to_move_cursor")
        setAnalyticsProperty(keyboardSettingsManager.cursorActiveDistance, format: "%.1f", forName: "pref_cursor_atv_distance")
        setAnalyticsProperty(keyboardSettingsManager.cursorMoveInterval, format: "%.1f", forName: "pref_cursor_mv_interval")
        
        // 외형 설정
        setAnalyticsProperty(keyboardSettingsManager.keyboardHeight, format: "%.1f", forName: "pref_keyboard_height")
        setAnalyticsProperty(keyboardSettingsManager.isNumericKeypadEnabled, forName: "pref_numeric_keypad")
        setAnalyticsProperty(keyboardSettingsManager.isOneHandedKeyboardEnabled, forName: "pref_one_handed_keyboard")
        setAnalyticsProperty(keyboardSettingsManager.oneHandedKeyboardWidth, format: "%.1f", forName: "pref_one_handed_width")
        
        logger.debug("Firebase Analytics User Properties 초기화 완료")
    }
}

// MARK: - SYKeyboardApp

@main
struct SYKeyboardApp: App {
    
    // MARK: - Properties
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.openURL) var openURL
    
    // MARK: - Content
    
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
