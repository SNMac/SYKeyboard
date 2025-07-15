//
//  UserDefaultsKeys.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/15/25.
//

import Foundation

/// `UserDefaults`의 키값 관리
enum UserDefaultsKeys {
    /* 피드백 설정 */
    /// 소리 피드백
    static let isSoundFeedbackEnabled = "isSoundFeedbackEnabled"
    /// 햅틱 피드백
    static let isHapticFeedbackEnabled = "isHapticFeedbackEnabled"
    
    /* 입력 설정 */
    /// 텍스트 대치
    static let isTextReplacementEnabled = "isTextReplacementEnabled"
    /// 스페이스/리턴 입력 후 한글 키보드로 변경
    static let isAutoChangeToHangeulEnabled = "isAutoChangeToHangeulEnabled"
    
    /* 입력 설정 -> 속도/커서 설정 */
    /// 반복 지연 시간
    static let longPressDuration = "longPressDuration"
    /// 키 반복 속도
    static let repeatRate = "repeatRate"
    /// 활성화 드래그 거리
    static let cursorActiveDistance = "cursorActiveDistance"
    /// 이동 드래그 간격
    static let cursorMoveInterval = "cursorMoveInterval"
    
    /* 외형 설정 */
    /// 키보드 높이
    static let keyboardHeight = "keyboardHeight"
    /// 숫자 키패드 활성화
    static let isNumericKeypadEnabled = "isNumericKeypadEnabled"
    /// 한 손 키보드 활성화
    static let isOneHandedKeyboardEnabled = "isOneHandedKeyboardEnabled"
    /// 한 손 키보드 너비
    static let oneHandedKeyboardWidth = "oneHandedKeyboardWidth"
    
    /* 기타 설정 */
    /// 키보드 전환 버튼(􀆪) 표시 설정용
    static let needsInputModeSwitchKey = "needsInputModeSwitchKey"
    /// 한 손 키보드 저장용
    static let currentOneHandedKeyboard = "currentOneHandedKeyboard"
    /// 온보딩 여부
    static let isOnboarding = "isOnboarding"
    /// 앱의 특정 기능 또는 키보드를 실행한 횟수
    static let reviewCounter = "reviewCounter"
    /// 마지막으로 리뷰를 요청한 빌드
    static let lastBuildPromptedForReview = "lastBuildPromptedForReview"
}
