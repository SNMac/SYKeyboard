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
    private let storage: UserDefaults
    
    /// 값을 저장할 키값
    private let key: String
    /// 기본값
    private let defaultValue: T
    
    public var wrappedValue: T {
        get { storage.object(forKey: key) as? T ?? defaultValue }
        set { storage.set(newValue, forKey: key) }
    }
    
    // MARK: Initializer
    
    init(
        storage: UserDefaults = UserDefaultsManager.defaultStorage,
        key: String,
        defaultValue: T
    ) {
        self.storage = storage
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
    private let storage: UserDefaults
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
    
    init(
        storage: UserDefaults = UserDefaultsManager.defaultStorage,
        key: String,
        defaultValue: T
    ) {
        self.storage = storage
        self.key = key
        self.defaultValue = defaultValue
    }
}

// MARK: - UserDefaultsManager

/// `UserDefaults`를 관리하는 싱글톤 매니저
final public class UserDefaultsManager {
    
    // MARK: Properties
    
    /// 데이터를 저장할 `UserDefaults`
    public let storage: UserDefaults
    
    // MARK: Singleton Initializer
    
    public static let shared = UserDefaultsManager()

    init(storage: UserDefaults = UserDefaultsManager.defaultStorage) {
        self.storage = storage

        _isSoundFeedbackEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isSoundFeedbackEnabled,
            defaultValue: DefaultValues.isSoundFeedbackEnabled
        )
        _isHapticFeedbackEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isHapticFeedbackEnabled,
            defaultValue: DefaultValues.isHapticFeedbackEnabled
        )
        _isTextReplacementEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isTextReplacementEnabled,
            defaultValue: DefaultValues.isTextReplacementEnabled
        )
        _isPredictiveTextEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isPredictiveTextEnabled,
            defaultValue: DefaultValues.isPredictiveTextEnabled
        )
        _isUndoRedoEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isUndoRedoEnabled,
            defaultValue: DefaultValues.isUndoRedoEnabled
        )
        _isDragToMoveCursorEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isDragToMoveCursorEnabled,
            defaultValue: DefaultValues.isDragToMoveCursorEnabled
        )
        _isPeriodShortcutEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isPeriodShortcutEnabled,
            defaultValue: DefaultValues.isPeriodShortcutEnabled
        )
        _isAutoChangeToPrimaryEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isAutoChangeToPrimaryEnabled,
            defaultValue: DefaultValues.isAutoChangeToPrimaryEnabled
        )
        _longPressDuration = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.longPressDuration,
            defaultValue: DefaultValues.longPressDuration
        )
        _repeatRate = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.repeatRate,
            defaultValue: DefaultValues.repeatRate
        )
        _cursorActiveDistance = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.cursorActiveDistance,
            defaultValue: DefaultValues.cursorActiveDistance
        )
        _cursorMoveInterval = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.cursorMoveInterval,
            defaultValue: DefaultValues.cursorMoveInterval
        )
        _keyboardHeight = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.keyboardHeight,
            defaultValue: DefaultValues.keyboardHeight
        )
        _isNumericKeypadEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isNumericKeypadEnabled,
            defaultValue: DefaultValues.isNumericKeypadEnabled
        )
        _isOneHandedKeyboardEnabled = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isOneHandedKeyboardEnabled,
            defaultValue: DefaultValues.isOneHandedKeyboardEnabled
        )
        _oneHandedKeyboardWidth = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.oneHandedKeyboardWidth,
            defaultValue: DefaultValues.oneHandedKeyboardWidth
        )
        _needsInputModeSwitchKey = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.needsInputModeSwitchKey,
            defaultValue: DefaultValues.needsInputModeSwitchKey
        )
        _lastOneHandedMode = UserDefaultsRawRepresentableWrapper(
            storage: storage,
            key: UserDefaultsKeys.lastOneHandedMode,
            defaultValue: DefaultValues.lastOneHandedMode
        )
        _isRequestFullAccessOverlayClosed = UserDefaultsWrapper(
            storage: storage,
            key: UserDefaultsKeys.isRequestFullAccessOverlayClosed,
            defaultValue: DefaultValues.isRequestFullAccessOverlayClosed
        )
    }
    
    // MARK: 피드백 설정
    
    /// 소리 피드백
    @UserDefaultsWrapper(key: UserDefaultsKeys.isSoundFeedbackEnabled, defaultValue: DefaultValues.isSoundFeedbackEnabled)
    public var isSoundFeedbackEnabled: Bool
    /// 햅틱 피드백
    @UserDefaultsWrapper(key: UserDefaultsKeys.isHapticFeedbackEnabled, defaultValue: DefaultValues.isHapticFeedbackEnabled)
    public var isHapticFeedbackEnabled: Bool
    
    // MARK: 자동완성 텍스트 설정
    
    /// 텍스트 대치
    @UserDefaultsWrapper(key: UserDefaultsKeys.isTextReplacementEnabled, defaultValue: DefaultValues.isTextReplacementEnabled)
    public var isTextReplacementEnabled: Bool
    /// 자동완성 텍스트
    @UserDefaultsWrapper(key: UserDefaultsKeys.isPredictiveTextEnabled, defaultValue: DefaultValues.isPredictiveTextEnabled)
    public var isPredictiveTextEnabled: Bool
    /// Undo/Redo 기능 활성화 여부
    @UserDefaultsWrapper(key: UserDefaultsKeys.isUndoRedoEnabled, defaultValue: DefaultValues.isUndoRedoEnabled)
    public var isUndoRedoEnabled: Bool
    
    // MARK: 입력 설정
    
    /// 선택한 길게 누르기 동작
    public var selectedLongPressAction: LongPressAction {
        get {
            guard let rawValue = storage.object(forKey: UserDefaultsKeys.selectedLongPressAction) as? LongPressAction.RawValue,
                  let value = LongPressAction(rawValue: rawValue) else {
                return DefaultValues.selectedLongPressAction
            }
            return value
        }
        set {
            storage.set(newValue.rawValue, forKey: UserDefaultsKeys.selectedLongPressAction)
        }
    }
    /// 드래그하여 커서 이동
    @UserDefaultsWrapper(key: UserDefaultsKeys.isDragToMoveCursorEnabled, defaultValue: DefaultValues.isDragToMoveCursorEnabled)
    public var isDragToMoveCursorEnabled: Bool
    /// '.' 단축키
    @UserDefaultsWrapper(key: UserDefaultsKeys.isPeriodShortcutEnabled, defaultValue: DefaultValues.isPeriodShortcutEnabled)
    public var isPeriodShortcutEnabled: Bool
    /// 스페이스/리턴 입력 후 주 키보드로 변경
    @UserDefaultsWrapper(key: UserDefaultsKeys.isAutoChangeToPrimaryEnabled, defaultValue: DefaultValues.isAutoChangeToPrimaryEnabled)
    public var isAutoChangeToPrimaryEnabled: Bool
    
    // MARK: 입력 설정 -> 속도/커서 설정
    
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
    
    // MARK: 외형 설정
    
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
    
    // MARK: 기타 설정
    
    /// 키보드 전환 버튼(􀆪) 표시 설정용
    @UserDefaultsWrapper(key: UserDefaultsKeys.needsInputModeSwitchKey, defaultValue: DefaultValues.needsInputModeSwitchKey)
    public var needsInputModeSwitchKey: Bool
    /// 한 손 키보드 저장용
    @UserDefaultsRawRepresentableWrapper(key: UserDefaultsKeys.lastOneHandedMode, defaultValue: DefaultValues.lastOneHandedMode)
    public var lastOneHandedMode: OneHandedMode
    /// 전체 접근 허용 안내 오버레이 닫음 여부
    @UserDefaultsWrapper(key: UserDefaultsKeys.isRequestFullAccessOverlayClosed, defaultValue: DefaultValues.isRequestFullAccessOverlayClosed)
    public var isRequestFullAccessOverlayClosed: Bool
}

extension UserDefaultsManager {
    static let defaultStorage: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
            fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
        }
        return userDefaults
    }()
}
