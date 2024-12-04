//
//  GlobalValues.swift
//  SYKeyboard, Naratgeul
//
//  Created by 서동환 on 9/4/24.
//

import Foundation

struct GlobalValues {
    private init() {}
    
    static let defaultKeyboardHeight: Double = 240.0
    static let defaultOneHandWidth: Double = 320.0
    static let defaultLongPressSpeed: Double = 0.5
    static let defaultRepeatTimerSpeed: Double = 0.05
    static let defaultCursorActiveWidth: Double = 50.0
    static let defaultCursorMoveWidth: Double = 5.0
    
    static func setupDefaults(_ defaults: UserDefaults?) {
        // UserDefaults 값이 존재하는지 확인하고, 없으면 새로 만듬
        
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
        // 스페이스 후 한글 자판으로 변경
        if defaults?.object(forKey: "isAutoChangeToHangeulEnabled") == nil {
            defaults?.set(true, forKey: "isAutoChangeToHangeulEnabled")
        }
        
        /* 입력 설정 -> 속도/커서 설정 */
        // 길게 누르기 속도
        if defaults?.object(forKey: "longPressSpeed") == nil {
            defaults?.set(GlobalValues.defaultLongPressSpeed, forKey: "longPressSpeed")
        }
        // 반복 입력 속도
        if defaults?.object(forKey: "repeatTimerSpeed") == nil {
            defaults?.set(GlobalValues.defaultRepeatTimerSpeed, forKey: "repeatTimerSpeed")
        }
        // 커서 이동 활성화 거리
        if defaults?.object(forKey: "cursorActiveWidth") == nil {
            defaults?.set(GlobalValues.defaultCursorActiveWidth, forKey: "cursorActiveWidth")
        }
        // 커서 이동 간격
        if defaults?.object(forKey: "cursorMoveWidth") == nil {
            defaults?.set(GlobalValues.defaultCursorMoveWidth, forKey: "cursorMoveWidth")
        }
        
        /* 외형 설정 */
        // 키보드 높이
        if defaults?.object(forKey: "keyboardHeight") == nil {
            defaults?.set(GlobalValues.defaultKeyboardHeight, forKey: "keyboardHeight")
        }
        // 숫자 패드 활성화
        if defaults?.object(forKey: "isNumberKeyboardTypeEnabled") == nil {
            defaults?.set(true, forKey: "isNumberKeyboardTypeEnabled")
        }
        // 한손 키보드 활성화
        if defaults?.object(forKey: "isOneHandTypeEnabled") == nil {
            defaults?.set(true, forKey: "isOneHandTypeEnabled")
        }
        // 한손 키보드 너비
        if defaults?.object(forKey: "oneHandWidth") == nil {
            defaults?.set(GlobalValues.defaultOneHandWidth, forKey: "oneHandWidth")
        }
        
        /* 키보드 전환 버튼 표시 설정용 */
        if defaults?.object(forKey: "needsInputModeSwitchKey") == nil {
            defaults?.set(true, forKey: "needsInputModeSwitchKey")
        }
        /* 키보드 한손 모드 저장용 (0 = 왼쪽, 1 = 가운데, 2 = 오른쪽) */
        if defaults?.object(forKey: "currentOneHandType") == nil {
            defaults?.set(1, forKey: "currentOneHandType")
        }
        /* 화면 너비 저장용 */
        if defaults?.object(forKey: "screenWidth") == nil {
            defaults?.set(1.0, forKey: "screenWidth")
        }
    }
}
