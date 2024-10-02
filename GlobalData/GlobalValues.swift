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
    static let defaultLongPressSpeed: Double = 0.5
    static let defaultRepeatTimerSpeed: Double = 0.05
    
    static func setupDefaults(_ defaults: UserDefaults?) {
        // UserDefaults 값이 존재하는지 확인하고, 없으면 새로 만듬
        
        /* 피드백 설정 */
        // 소리 피드백
        if defaults?.object(forKey: "isSoundFeedbackEnabled") == nil {
            defaults?.setValue(true, forKey: "isSoundFeedbackEnabled")
        }
        // 햅틱 피드백
        if defaults?.object(forKey: "isHapticFeedbackEnabled") == nil {
            defaults?.setValue(true, forKey: "isHapticFeedbackEnabled")
        }
        
        /* 입력 설정 */
        // 자동 완성 및 추천
        if defaults?.object(forKey: "isAutocompleteEnabled") == nil {
            defaults?.setValue(true, forKey: "isAutocompleteEnabled")
        }
        // 텍스트 대치
        if defaults?.object(forKey: "isTextReplacementEnabled") == nil {
            defaults?.setValue(true, forKey: "isTextReplacementEnabled")
        }
        // 스페이스 후 한글 자판으로 변경
        if defaults?.object(forKey: "isAutoChangeToHangeulEnabled") == nil {
            defaults?.setValue(true, forKey: "isAutoChangeToHangeulEnabled")
        }
        
        /* 입력 설정 -> 속도 설정 */
        // 길게 누르기 속도
        if defaults?.object(forKey: "longPressSpeed") == nil {
            defaults?.setValue(GlobalValues.defaultLongPressSpeed, forKey: "longPressSpeed")
        }
        // 반복 속도
        if defaults?.object(forKey: "repeatTimerSpeed") == nil {
            defaults?.setValue(GlobalValues.defaultRepeatTimerSpeed, forKey: "repeatTimerSpeed")
        }
        
        /* 외형 설정 */
        // 키보드 높이
        if defaults?.object(forKey: "keyboardHeight") == nil {
            defaults?.setValue(GlobalValues.defaultKeyboardHeight, forKey: "keyboardHeight")
        }
        // 숫자 패드 활성화
        if defaults?.object(forKey: "isNumberKeyboardTypeEnabled") == nil {
            defaults?.setValue(true, forKey: "isNumberKeyboardTypeEnabled")
        }
        // 키보드 전환 버튼 표시 설정용
        if defaults?.object(forKey: "needsInputModeSwitchKey") == nil {
            defaults?.setValue(false, forKey: "needsInputModeSwitchKey")
        }
    }
}
