//
//  GlobalData.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import Foundation

final class GlobalData {
    static let shared = GlobalData()
    
    let defaultKeyboardHeight: Double = 240
    let defaultLongPressSpeed: Double = 0.6
    let defaultRepeatTimerSpeed: Double = 0.06
    
    func setupDefaults(defaults: UserDefaults?) {
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
        /* 입력 설정 -> 속도 설정 */
        // 길게 누르기 속도
        if defaults?.object(forKey: "longPressSpeed") == nil {
            defaults?.setValue(GlobalData().defaultLongPressSpeed, forKey: "longPressSpeed")
        }
        // 반복 속도
        if defaults?.object(forKey: "repeatTimerSpeed") == nil {
            defaults?.setValue(GlobalData().defaultRepeatTimerSpeed, forKey: "repeatTimerSpeed")
        }
        
        /* 외형 설정 */
        // 키보드 높이
        if defaults?.object(forKey: "keyboardHeight") == nil {
            defaults?.setValue(GlobalData().defaultKeyboardHeight, forKey: "keyboardHeight")
        }
        // 키보드 높이 조절 슬라이더 값(임시)
        if defaults?.object(forKey: "tempKeyboardHeight") == nil {
            defaults?.setValue(GlobalData().defaultKeyboardHeight, forKey: "tempKeyboardHeight")
        }
    }
}
