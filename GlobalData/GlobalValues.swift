//
//  GlobalValues.swift
//  SYKeyboard, Keyboard
//
//  Created by 서동환 on 9/4/24.
//

import Foundation

struct GlobalValues {
    private init() {}
    
    static let groupBundleID = "group.github.com-SNMac.SYKeyboard"
    
    static let defaultKeyboardHeight: Double = 240.0
    static let defaultOneHandedKeyboardWidth: Double = 320.0
    static let defaultLongPressDuration: Double = 0.5
    static let defaultRepeatRate: Double = 0.05
    static let defaultCursorActiveWidth: Double = 50.0
    static let defaultCursorMoveWidth: Double = 5.0
    
    static func setupDefaults(_ defaults: UserDefaults?) {
        // UserDefaults 값이 존재하는지 확인하고, 없으면 새로 만듬
        
        // 온보딩 여부
        if defaults?.object(forKey: "isOnboarding") == nil {
            defaults?.set(true, forKey: "isOnboarding")
        }
        
        // 앱의 특정 기능 또는 키보드를 실행한 횟수
        if defaults?.object(forKey: "reviewCounter") == nil {
            defaults?.set(0, forKey: "reviewCounter")
        }
        
        // 마지막으로 리뷰를 요청한 빌드
        if defaults?.object(forKey: "lastBuildPromptedForReview") == nil {
            defaults?.set("", forKey: "lastBuildPromptedForReview")
        }
        
        /* 피드백 설정 */
        // 소리 피드백
        if defaults?.object(forKey: "isSoundFeedbackEnabled") == nil {
            defaults?.set(true, forKey: "isSoundFeedbackEnabled")
        }
        // 햅틱 피드백
        if defaults?.object(forKey: "isHapticFeedbackEnabled") == nil {
            defaults?.set(true, forKey: "isHapticFeedbackEnabled")
        }
        
        /* 입력 설정 */
        // 텍스트 대치
        if defaults?.object(forKey: "isTextReplacementEnabled") == nil {
            defaults?.set(true, forKey: "isTextReplacementEnabled")
        }
        // 스페이스/리턴 입력 후 한글 키보드로 변경
        if defaults?.object(forKey: "isAutoChangeToHangeulEnabled") == nil {
            defaults?.set(true, forKey: "isAutoChangeToHangeulEnabled")
        }
        
        /* 입력 설정 -> 속도/커서 설정 */
        // 반복 지연 시간
        if defaults?.object(forKey: "longPressDuration") == nil {
            defaults?.set(GlobalValues.defaultLongPressDuration, forKey: "longPressDuration")
        }
        // 키 반복 속도
        if defaults?.object(forKey: "repeatRate") == nil {
            defaults?.set(GlobalValues.defaultRepeatRate, forKey: "repeatRate")
        }
        // 활성화 드래그 거리
        if defaults?.object(forKey: "cursorActiveWidth") == nil {
            defaults?.set(GlobalValues.defaultCursorActiveWidth, forKey: "cursorActiveWidth")
        }
        // 이동 드래그 간격
        if defaults?.object(forKey: "cursorMoveWidth") == nil {
            defaults?.set(GlobalValues.defaultCursorMoveWidth, forKey: "cursorMoveWidth")
        }
        
        /* 외형 설정 */
        // 키보드 높이
        if defaults?.object(forKey: "keyboardHeight") == nil {
            defaults?.set(GlobalValues.defaultKeyboardHeight, forKey: "keyboardHeight")
        }
        // 숫자 키패드 활성화
        if defaults?.object(forKey: "isNumericKeypadEnabled") == nil {
            defaults?.set(true, forKey: "isNumericKeypadEnabled")
        }
        // 한 손 키보드 활성화
        if defaults?.object(forKey: "isOneHandedKeyboardEnabled") == nil {
            defaults?.set(true, forKey: "isOneHandedKeyboardEnabled")
        }
        // 한 손 키보드 너비
        if defaults?.object(forKey: "oneHandedKeyboardWidth") == nil {
            defaults?.set(GlobalValues.defaultOneHandedKeyboardWidth, forKey: "oneHandedKeyboardWidth")
        }
        
        /* 키보드 전환 버튼(􀆪) 표시 설정용 */
        if defaults?.object(forKey: "needsInputModeSwitchKey") == nil {
            defaults?.set(true, forKey: "needsInputModeSwitchKey")
        }
        /* 한 손 키보드 저장용 (0 = 왼쪽, 1 = 가운데, 2 = 오른쪽) */
        if defaults?.object(forKey: "currentOneHandedKeyboard") == nil {
            defaults?.set(1, forKey: "currentOneHandedKeyboard")
        }
        /* 화면 너비 저장용 */
        if defaults?.object(forKey: "screenWidth") == nil {
            defaults?.set(1.0, forKey: "screenWidth")
        }
    }
}
