//
//  UserDefaultsManager.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/4/24.
//

import Foundation

// MARK: - UserDefaultsWrapper

/// 반복되는 코드를 줄이기 위한 프로퍼티 관리 코드
@propertyWrapper
public struct UserDefaultsWrapper<T: Codable> {
    
    // MARK: Properties
    
    /// 데이터를 저장할 `UserDefaults`
    private let storage: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
            fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
        }
        return userDefaults
    }()
    
    /// 값을 저장할 키값
    private let key: String
    /// 기본값
    private let defaultValue: T
    
    public var wrappedValue: T {
        get { storage.object(forKey: key) as? T ?? defaultValue }
        set { storage.set(newValue, forKey: key) }
    }
    
    // MARK: Initializer
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

// MARK: - UserDefaultsRawRepresentableWrapper

/// `RawRepresentable` 타입을 위한 프로퍼티 래퍼
@propertyWrapper
public struct UserDefaultsRawRepresentableWrapper<T: RawRepresentable> {
    
    // MARK: Properties
    
    /// 데이터를 저장할 `UserDefaults`
    private let storage: UserDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID)!
    /// 값을 저장할 키값
    private let key: String
    /// 기본값
    private let defaultValue: T
    
    public var wrappedValue: T {
        get {
            guard let rawValue = storage.object(forKey: key) as? T.RawValue,
                  let value = T(rawValue: rawValue) else {
                return defaultValue
            }
            return value
        }
        set {
            storage.set(newValue.rawValue, forKey: key)
        }
    }
    
    // MARK: Initializer
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

// MARK: - UserDefaultsManager

/// `UserDefaults`를 관리하는 싱글톤 매니저
final public class UserDefaultsManager {
    
    // MARK: Properties
    
    /// 데이터를 저장할 `UserDefaults`
    public let storage: UserDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID)!
    
    // MARK: Singleton Initializer
    
    public static let shared = UserDefaultsManager()
    private init() {}
    
    // MARK: Getter
    
    /* 피드백 설정 */
    /// 소리 피드백
    @UserDefaultsWrapper(key: UserDefaultsKeys.isSoundFeedbackEnabled, defaultValue: DefaultValues.isSoundFeedbackEnabled)
    public var isSoundFeedbackEnabled: Bool
    /// 햅틱 피드백
    @UserDefaultsWrapper(key: UserDefaultsKeys.isHapticFeedbackEnabled, defaultValue: DefaultValues.isHapticFeedbackEnabled)
    public var isHapticFeedbackEnabled: Bool
    
    /* 입력 설정 */

    /// 길게 누르기 동작 - 반복 입력
    @UserDefaultsWrapper(key: UserDefaultsKeys.isLongPressToRepeatInputEnabled, defaultValue: DefaultValues.isLongPressToRepeatInputEnabled)
    public var isLongPressToRepeatInputEnabled: Bool
    /// 길게 누르기 동작 - 숫자 입력
    @UserDefaultsWrapper(key: UserDefaultsKeys.isLongPressToNumberInputEnabled, defaultValue: DefaultValues.isLongPressToNumberInputEnabled)
    public var isLongPressToNumberInputEnabled: Bool
    /// 드래그하여 커서 이동
    @UserDefaultsWrapper(key: UserDefaultsKeys.isDragToMoveCursorEnabled, defaultValue: DefaultValues.isDragToMoveCursorEnabled)
    public var isDragToMoveCursorEnabled: Bool
    /// 텍스트 대치
    @UserDefaultsWrapper(key: UserDefaultsKeys.isTextReplacementEnabled, defaultValue: DefaultValues.isTextReplacementEnabled)
    public var isTextReplacementEnabled: Bool

    /// 스페이스/리턴 입력 후 주 키보드로 변경
    @UserDefaultsWrapper(key: UserDefaultsKeys.isAutoChangeToPrimaryEnabled, defaultValue: DefaultValues.isAutoChangeToPrimaryEnabled)
    public var isAutoChangeToPrimaryEnabled: Bool
    
    /* 입력 설정 -> 속도/커서 설정 */
    /// 반복 지연 시간
    @UserDefaultsWrapper(key: UserDefaultsKeys.longPressDuration, defaultValue: DefaultValues.longPressDuration)
    public var longPressDuration: Double
    /// 키 반복 속도
    @UserDefaultsWrapper(key: UserDefaultsKeys.repeatRate, defaultValue: DefaultValues.repeatRate)
    public var repeatRate: Double
    /// 활성화 드래그 거리
    @UserDefaultsWrapper(key: UserDefaultsKeys.cursorActiveDistance, defaultValue: DefaultValues.cursorActiveDistance)
    public var cursorActiveDistance: Double
    /// 이동 드래그 간격
    @UserDefaultsWrapper(key: UserDefaultsKeys.cursorMoveInterval, defaultValue: DefaultValues.cursorMoveInterval)
    public var cursorMoveInterval: Double
    
    /* 외형 설정 */
    /// 키보드 높이
    @UserDefaultsWrapper(key: UserDefaultsKeys.keyboardHeight, defaultValue: DefaultValues.keyboardHeight)
    public var keyboardHeight: Double
    /// 숫자 키패드 활성화
    @UserDefaultsWrapper(key: UserDefaultsKeys.isNumericKeypadEnabled, defaultValue: DefaultValues.isNumericKeypadEnabled)
    public var isNumericKeypadEnabled: Bool
    /// 한 손 키보드 활성화
    @UserDefaultsWrapper(key: UserDefaultsKeys.isOneHandedKeyboardEnabled, defaultValue: DefaultValues.isOneHandedKeyboardEnabled)
    public var isOneHandedKeyboardEnabled: Bool
    /// 한 손 키보드 너비
    @UserDefaultsWrapper(key: UserDefaultsKeys.oneHandedKeyboardWidth, defaultValue: DefaultValues.oneHandedKeyboardWidth)
    public var oneHandedKeyboardWidth: Double
    
    /* 기타 설정 */
    /// 키보드 전환 버튼(􀆪) 표시 설정용
    @UserDefaultsWrapper(key: UserDefaultsKeys.needsInputModeSwitchKey, defaultValue: DefaultValues.needsInputModeSwitchKey)
    public var needsInputModeSwitchKey: Bool
    /// 한 손 키보드 저장용
    @UserDefaultsRawRepresentableWrapper(key: UserDefaultsKeys.lastOneHandedMode, defaultValue: DefaultValues.lastOneHandedMode)
    public var lastOneHandedMode: OneHandedMode
    /// 온보딩 여부
    @UserDefaultsWrapper(key: UserDefaultsKeys.isOnboarding, defaultValue: DefaultValues.isOnboarding)
    public var isOnboarding: Bool
    /// 전체 접근 허용 안내 오버레이 닫음 여부
    @UserDefaultsWrapper(key: UserDefaultsKeys.isRequestFullAccessOverlayClosed, defaultValue: DefaultValues.isRequestFullAccessOverlayClosed)
    public var isRequestFullAccessOverlayClosed: Bool
    /// 앱의 특정 기능 또는 키보드를 실행한 횟수
    @UserDefaultsWrapper(key: UserDefaultsKeys.reviewCounter, defaultValue: DefaultValues.reviewCounter)
    public var reviewCounter: Int
    /// 마지막으로 리뷰를 요청한 빌드
    @UserDefaultsWrapper(key: UserDefaultsKeys.lastBuildPromptedForReview, defaultValue: DefaultValues.lastBuildPromptedForReview)
    public var lastBuildPromptedForReview: String
}
