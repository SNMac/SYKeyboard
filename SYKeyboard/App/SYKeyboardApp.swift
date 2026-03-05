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
        
        // 한글 키보드
        let selectedHangeulKeyboardRaw = keyboardSettingsManager.selectedHangeulKeyboard.rawValue
        let hangeulKeyboard = HangeulKeyboardSelectView.HangeulKeyboard(rawValue: selectedHangeulKeyboardRaw) ?? .naratgeul
        Analytics.setUserProperty(hangeulKeyboard.analyticsValue,
                                  forName: "pref_hangeul_keyboard")
        
        // 피드백 설정
        let isSoundFeedbackEnabled = keyboardSettingsManager.isSoundFeedbackEnabled
        Analytics.setUserProperty(isSoundFeedbackEnabled ? "true" : "false",
                                  forName: "pref_sound_feedback")
        let isHapticFeedbackEnabled = keyboardSettingsManager.isHapticFeedbackEnabled
        Analytics.setUserProperty(isHapticFeedbackEnabled ? "true" : "false",
                                  forName: "pref_haptic_feedback")
        
        // 입력 설정
        let selectedLongPressActionRaw = keyboardSettingsManager.selectedLongPressAction.rawValue
        let longPressMode = InputSettingsView.LongPressMode(rawValue: selectedLongPressActionRaw) ?? .repeatInput
        Analytics.setUserProperty(longPressMode.analyticsValue,
                                  forName: "pref_long_press_action")
        let longPressDuration = keyboardSettingsManager.longPressDuration
        Analytics.setUserProperty(String(format: "%.2f", longPressDuration),
                                  forName: "pref_long_press_duration")
        let repeatRate = keyboardSettingsManager.repeatRate
        Analytics.setUserProperty(String(format: "%.3f", repeatRate),
                                  forName: "pref_repeat_rate")
        let isAutoCapitalizationEnabled = keyboardSettingsManager.isAutoCapitalizationEnabled
        Analytics.setUserProperty(isAutoCapitalizationEnabled ? "true" : "false",
                                  forName: "pref_auto_capitalization")
        let isTextReplacementEnabled = keyboardSettingsManager.isTextReplacementEnabled
        Analytics.setUserProperty(isTextReplacementEnabled ? "true" : "false",
                                  forName: "pref_text_replacement")
        let isPeriodShortcutEnabled = keyboardSettingsManager.isPeriodShortcutEnabled
        Analytics.setUserProperty(isPeriodShortcutEnabled ? "true" : "false",
                                  forName: "pref_period_shortcut")
        let isAutoChangeToPrimaryEnabled = keyboardSettingsManager.isAutoChangeToPrimaryEnabled
        Analytics.setUserProperty(isAutoChangeToPrimaryEnabled ? "true" : "false",
                                  forName: "pref_auto_change_primary")
        let isDragToMoveCursorEnabled = keyboardSettingsManager.isDragToMoveCursorEnabled
        Analytics.setUserProperty(isDragToMoveCursorEnabled ? "true" : "false",
                                  forName: "pref_drag_to_move_cursor")
        let cursorActiveDistance = keyboardSettingsManager.cursorActiveDistance
        Analytics.setUserProperty(String(format: "%.1f", cursorActiveDistance),
                                  forName: "pref_cursor_atv_distance")
        let cursorMoveInterval = keyboardSettingsManager.cursorMoveInterval
        Analytics.setUserProperty(String(format: "%.1f", cursorMoveInterval),
                                  forName: "pref_cursor_mv_interval")
        
        // 외형 설정
        let keyboardHeight = keyboardSettingsManager.keyboardHeight
        Analytics.setUserProperty(String(format: "%.1f", keyboardHeight),
                                  forName: "pref_keyboard_height")
        let isNumericKeypadEnabled = keyboardSettingsManager.isNumericKeypadEnabled
        Analytics.setUserProperty(isNumericKeypadEnabled ? "true" : "false",
                                  forName: "pref_numeric_keypad")
        let isOneHandedKeyboardEnabled = keyboardSettingsManager.isOneHandedKeyboardEnabled
        Analytics.setUserProperty(isOneHandedKeyboardEnabled ? "true" : "false",
                                  forName: "pref_one_handed_keyboard")
        let oneHandedKeyboardWidth = keyboardSettingsManager.oneHandedKeyboardWidth
        Analytics.setUserProperty(String(format: "%.1f", oneHandedKeyboardWidth),
                                  forName: "pref_one_handed_width")
        
        logger.debug("Firebase Analytics User Properties 초기화 완료")
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
