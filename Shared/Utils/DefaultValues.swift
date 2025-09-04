//
//  DefaultValues.swift
//  SYKeyboard, Keyboard
//
//  Created by 서동환 on 7/16/25.
//

/// `UserDefaultsManager`의 기본값 관리용
enum DefaultValues {
    
    /// 그룹 번들 ID
    static let groupBundleID = "group.github.com-SNMac.SYKeyboard"
    
    /* 피드백 설정 */
    /// 소리 피드백 기본값
    static let isSoundFeedbackEnabled: Bool = true
    /// 햅틱 피드백
    static let isHapticFeedbackEnabled: Bool = true
    
    /* 입력 설정 */
    /// 텍스트 대치 기본값
    static let isTextReplacementEnabled: Bool = true
    /// 스페이스/리턴 입력 후 한글 키보드로 변경 기본값
    static let isAutoChangeToHangeulEnabled: Bool = true
    
    static let keyboardHeight: Double = 240.0
    static let isNumericKeypadEnabled: Bool = true
    static let isOneHandedKeyboardEnabled: Bool = true
    static let oneHandedKeyboardWidth: Double = 320.0
    
    /* 입력 설정 -> 속도/커서 설정 */
    /// 반복 지연 시간 기본값
    static let longPressDuration: Double = 0.5
    /// 키 반복 속도 기본값
    static let repeatRate: Double = 0.05
    /// 활성화 드래그 거리 기본값
    static let cursorActiveDistance: Double = 50.0
    /// 이동 드래그 간격 기본값
    static let cursorMoveInterval: Double = 5.0
    
    /* 기타 설정 */
    /// 키보드 전환 버튼(􀆪) 표시 설정용 기본값
    static let needsInputModeSwitchKey: Bool = true
    /// 한 손 키보드 저장용 기본값
    static let lastOneHandedMode: OneHandedMode = .center
    /// 온보딩 여부 기본값
    static let isOnboarding: Bool = true
    /// 앱의 특정 기능 또는 키보드를 실행한 횟수 기본값
    static let reviewCounter: Int = 0
    /// 마지막으로 리뷰를 요청한 빌드 기본값
    static let lastBuildPromptedForReview: String = ""
}
