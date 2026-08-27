//
//  UserDefaultsKeys.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/15/25.
//

/// `UserDefaults`의 키값 관리용
public enum UserDefaultsKeys {
    
    // MARK: - 피드백 설정
    
    /// 소리 피드백
    public static let isSoundFeedbackEnabled = "isSoundFeedbackEnabled"
    /// 햅틱 피드백
    public static let isHapticFeedbackEnabled = "isHapticFeedbackEnabled"
    
    // MARK: - 자동완성 텍스트 설정

    /// 텍스트 대치
    public static let isTextReplacementEnabled = "isTextReplacementEnabled"
    /// 자동완성 텍스트
    public static let isPredictiveTextEnabled = "isPredictiveTextEnabled"
    /// Undo/Redo 기능 활성화 여부
    public static let isUndoRedoEnabled = "isUndoRedoEnabled"
    /// 수식 결과 표시
    public static let isShowMathResultsEnabled = "isShowMathResultsEnabled"
    
    // MARK: - 입력 설정
    
    /// 선택한 길게 누르기 동작
    public static let selectedLongPressAction = "selectedLongPressAction"
    /// 드래그하여 커서 이동
    public static let isDragToMoveCursorEnabled = "isDragToMoveCursorEnabled"
    /// '.' 단축키
    public static let isPeriodShortcutEnabled = "isPeriodShortcutEnabled"
    /// Smart Punctuation
    public static let isSmartPunctuationEnabled = "isSmartPunctuationEnabled"
    /// 스페이스/리턴 입력 후 주 키보드로 변경
    public static let isAutoChangeToPrimaryEnabled = "isAutoChangeToPrimaryEnabled"
    
    // MARK: - 입력 설정 -> 속도/커서 설정
    
    /// 반복 지연 시간
    public static let longPressDuration = "longPressDuration"
    /// 키 반복 속도
    public static let repeatRate = "repeatRate"
    /// 활성화 드래그 거리
    public static let cursorActiveDistance = "cursorActiveDistance"
    /// 이동 드래그 간격
    public static let cursorMoveInterval = "cursorMoveInterval"
    
    // MARK: - 외형 설정
    /// 키보드 높이
    public static let keyboardHeight = "keyboardHeight"
    /// 숫자 키패드 활성화
    public static let isNumericKeypadEnabled = "isNumericKeypadEnabled"
    /// 한 손 키보드 활성화
    public static let isOneHandedKeyboardEnabled = "isOneHandedKeyboardEnabled"
    /// 한 손 키보드 너비
    public static let oneHandedKeyboardWidth = "oneHandedKeyboardWidth"
    /// 나랏글 '획', '쌍' 버튼을 'ㆍ', 'ᆢ'로 표기
    public static let isNaratgeulDotLabelEnabled = "isNaratgeulDotLabelEnabled"
    
    // MARK: - 기타 설정
    /// 키보드 전환 버튼(􀆪) 표시 설정용
    public static let needsInputModeSwitchKey = "needsInputModeSwitchKey"
    /// 한 손 키보드 저장용
    public static let lastOneHandedMode = "lastOneHandedMode"
    /// 한영 통합 키보드 마지막 언어 mode 저장용
    public static let lastHangeulEnglishLanguageMode = "lastHangeulEnglishLanguageMode"
    /// 전체 접근 허용 안내 오버레이 닫음 여부
    public static let isRequestFullAccessOverlayClosed = "isRequestFullAccessOverlayClosed"
}
