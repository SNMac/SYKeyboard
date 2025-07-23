//
//  UserDefaultsManager.swift
//  SYKeyboard, Keyboard
//
//  Created by 서동환 on 9/4/24.
//

import Foundation

/// 반복되는 코드를 줄이기 위한 프로퍼티 관리 코드
@propertyWrapper
struct UserDefaultsWrapper<T: Codable> {
    /// 데이터를 저장할 `UserDefaults`
    private let storage: UserDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID)!
    /// 값을 저장할 키값
    private let key: String
    /// 기본값
    private let defaultValue: T
    
    var wrappedValue: T {
        get { storage.object(forKey: key) as? T ?? defaultValue }
        set { storage.set(newValue, forKey: key) }
    }
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

/// `UserDefaults`를 관리하는 싱글톤 매니저
final class UserDefaultsManager {
    
    // MARK: - Singleton Initializer
    
    static let shared = UserDefaultsManager()
    private init() {}
    
    // MARK: - Getter
    
    /* 피드백 설정 */
    /// 소리 피드백
    @UserDefaultsWrapper(key: UserDefaultsKeys.isSoundFeedbackEnabled, defaultValue: DefaultValues.isSoundFeedbackEnabled)
    var isSoundFeedbackEnabled: Bool
    /// 햅틱 피드백
    @UserDefaultsWrapper(key: UserDefaultsKeys.isHapticFeedbackEnabled, defaultValue: DefaultValues.isHapticFeedbackEnabled)
    var isHapticFeedbackEnabled: Bool
    
    /* 입력 설정 */
    /// 텍스트 대치
    @UserDefaultsWrapper(key: UserDefaultsKeys.isTextReplacementEnabled, defaultValue: DefaultValues.isTextReplacementEnabled)
    var isTextReplacementEnabled: Bool
    /// 스페이스/리턴 입력 후 한글 키보드로 변경
    @UserDefaultsWrapper(key: UserDefaultsKeys.isAutoChangeToHangeulEnabled, defaultValue: DefaultValues.isAutoChangeToHangeulEnabled)
    var isAutoChangeToHangeulEnabled: Bool
    
    /* 입력 설정 -> 속도/커서 설정 */
    /// 반복 지연 시간
    @UserDefaultsWrapper(key: UserDefaultsKeys.longPressDuration, defaultValue: DefaultValues.longPressDuration)
    var longPressDuration: Double
    /// 키 반복 속도
    @UserDefaultsWrapper(key: UserDefaultsKeys.repeatRate, defaultValue: DefaultValues.repeatRate)
    var repeatRate: Double
    /// 활성화 드래그 거리
    @UserDefaultsWrapper(key: UserDefaultsKeys.cursorActiveDistance, defaultValue: DefaultValues.cursorActiveDistance)
    var cursorActiveDistance: Double
    /// 이동 드래그 간격
    @UserDefaultsWrapper(key: UserDefaultsKeys.cursorMoveInterval, defaultValue: DefaultValues.cursorMoveInterval)
    var cursorMoveInterval: Double
    
    /* 외형 설정 */
    /// 키보드 높이
    @UserDefaultsWrapper(key: UserDefaultsKeys.keyboardHeight, defaultValue: DefaultValues.keyboardHeight)
    var keyboardHeight: Double
    /// 숫자 키패드 활성화
    @UserDefaultsWrapper(key: UserDefaultsKeys.isNumericKeypadEnabled, defaultValue: DefaultValues.isNumericKeypadEnabled)
    var isNumericKeypadEnabled: Bool
    /// 한 손 키보드 활성화
    @UserDefaultsWrapper(key: UserDefaultsKeys.isOneHandedKeyboardEnabled, defaultValue: DefaultValues.isOneHandedKeyboardEnabled)
    var isOneHandedKeyboardEnabled: Bool
    /// 한 손 키보드 너비
    @UserDefaultsWrapper(key: UserDefaultsKeys.oneHandedKeyboardWidth, defaultValue: DefaultValues.oneHandedKeyboardWidth)
    var oneHandedKeyboardWidth: Double
    
    /* 기타 설정 */
    /// 키보드 전환 버튼(􀆪) 표시 설정용
    @UserDefaultsWrapper(key: UserDefaultsKeys.needsInputModeSwitchKey, defaultValue: DefaultValues.needsInputModeSwitchKey)
    var needsInputModeSwitchKey: Bool
    /// 한 손 키보드 저장용
    var lastOneHandedMode: OneHandedMode {
        get {
            let storage: UserDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID)!
            return OneHandedMode(rawValue: storage.integer(forKey: UserDefaultsKeys.lastOneHandedMode)) ?? DefaultValues.lastOneHandedMode
        }
        set {
            let storage: UserDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID)!
            storage.set(newValue.rawValue, forKey: UserDefaultsKeys.lastOneHandedMode)
        }
    }
    /// 온보딩 여부
    @UserDefaultsWrapper(key: UserDefaultsKeys.isOnboarding, defaultValue: DefaultValues.isOnboarding)
    var isOnboarding: Bool
    /// 앱의 특정 기능 또는 키보드를 실행한 횟수
    @UserDefaultsWrapper(key: UserDefaultsKeys.reviewCounter, defaultValue: DefaultValues.reviewCounter)
    var reviewCounter: Int
    /// 마지막으로 리뷰를 요청한 빌드
    @UserDefaultsWrapper(key: UserDefaultsKeys.lastBuildPromptedForReview, defaultValue: DefaultValues.lastBuildPromptedForReview)
    var lastBuildPromptedForReview: String
}
