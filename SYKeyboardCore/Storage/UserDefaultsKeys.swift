//
//  UserDefaultsKeys.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/15/25.
//

/// `UserDefaults`의 키값 관리용
public enum UserDefaultsKeys {
    /* 피드백 설정 */
    /// 소리 피드백
    public static let isSoundFeedbackEnabled = "isSoundFeedbackEnabled"
    /// 햅틱 피드백
    public static let isHapticFeedbackEnabled = "isHapticFeedbackEnabled"
    
    /* 입력 설정 */
    /// 선택한 한글 키보드
    public static let selectedHangeulKeyboard = "selectedHangeulKeyboard"
    /// 길게 터치하여 반복 입력
    public static let isLongPressToRepeatInputEnabled = "isLongPressToRepeatInputEnabled"
    /// 길게 터치하여 숫자 입력
    public static let isLongPressToNumberInputEnabled = "isLongPressToNumberInputEnabled"
    /// 텍스트 대치
    public static let isTextReplacementEnabled = "isTextReplacementEnabled"
    /// 자동 대문자
    public static let isAutoCapitalizationEnabled = "isAutoCapitalizationEnabled"
    /// 스페이스/리턴 입력 후 주 키보드로 변경
    public static let isAutoChangeToPrimaryEnabled = "isAutoChangeToPrimaryEnabled"
    
    /* 입력 설정 -> 속도/커서 설정 */
    /// 반복 지연 시간
    public static let longPressDuration = "longPressDuration"
    /// 키 반복 속도
    public static let repeatRate = "repeatRate"
    /// 활성화 드래그 거리
    public static let cursorActiveDistance = "cursorActiveDistance"
    /// 이동 드래그 간격
    public static let cursorMoveInterval = "cursorMoveInterval"
    
    /* 외형 설정 */
    /// 키보드 높이
    public static let keyboardHeight = "keyboardHeight"
    /// 숫자 키패드 활성화
    public static let isNumericKeypadEnabled = "isNumericKeypadEnabled"
    /// 한 손 키보드 활성화
    public static let isOneHandedKeyboardEnabled = "isOneHandedKeyboardEnabled"
    /// 한 손 키보드 너비
    public static let oneHandedKeyboardWidth = "oneHandedKeyboardWidth"
    
    /* 기타 설정 */
    /// 키보드 전환 버튼(􀆪) 표시 설정용
    public static let needsInputModeSwitchKey = "needsInputModeSwitchKey"
    /// 한 손 키보드 저장용
    public static let lastOneHandedMode = "lastOneHandedMode"
    /// 온보딩 여부
    public static let isOnboarding = "isOnboarding"
    /// 전체 접근 허용 안내 오버레이 닫음 여부
    public static let isRequestFullAccessOverlayClosed = "isRequestFullAccessOverlayClosed"
    /// 앱의 특정 기능 또는 키보드를 실행한 횟수
    public static let reviewCounter = "reviewCounter"
    /// 마지막으로 리뷰를 요청한 빌드
    public static let lastBuildPromptedForReview = "lastBuildPromptedForReview"
}
