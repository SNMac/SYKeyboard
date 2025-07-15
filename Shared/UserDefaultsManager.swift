//
//  UserDefaultsManager.swift
//  SYKeyboard, Keyboard
//
//  Created by 서동환 on 9/4/24.
//

import Foundation

/// `UserDefaults` 매니저 `class`
final class UserDefaultsManager {
    
    // MARK: - Properties
    
    let groupBundleID = DefaultValues.groupBundleID
    
    // MARK: - Initializer
    
    static let shared = UserDefaultsManager()
    private init() {}
    
    // MARK: - Methods
    
    /// UserDefaults 값이 존재하는지 확인하고, 없으면 새로 만드는 메서드
    func setupDefaults(_ defaults: UserDefaults?) {
        /* 피드백 설정 */
        // 소리 피드백
        if defaults?.object(forKey: UserDefaultsKeys.isSoundFeedbackEnabled) == nil {
            defaults?.set(DefaultValues.isSoundFeedbackEnabled, forKey: UserDefaultsKeys.isSoundFeedbackEnabled)
        }
        // 햅틱 피드백
        if defaults?.object(forKey: UserDefaultsKeys.isHapticFeedbackEnabled) == nil {
            defaults?.set(DefaultValues.isHapticFeedbackEnabled, forKey: UserDefaultsKeys.isHapticFeedbackEnabled)
        }
        
        /* 입력 설정 */
        // 텍스트 대치
        if defaults?.object(forKey: UserDefaultsKeys.isTextReplacementEnabled) == nil {
            defaults?.set(DefaultValues.isTextReplacementEnabled, forKey: UserDefaultsKeys.isTextReplacementEnabled)
        }
        // 스페이스/리턴 입력 후 한글 키보드로 변경
        if defaults?.object(forKey: UserDefaultsKeys.isAutoChangeToHangeulEnabled) == nil {
            defaults?.set(DefaultValues.isAutoChangeToHangeulEnabled, forKey: UserDefaultsKeys.isAutoChangeToHangeulEnabled)
        }
        
        /* 입력 설정 -> 속도/커서 설정 */
        // 반복 지연 시간
        if defaults?.object(forKey: UserDefaultsKeys.longPressDuration) == nil {
            defaults?.set(DefaultValues.longPressDuration, forKey: UserDefaultsKeys.longPressDuration)
        }
        // 키 반복 속도
        if defaults?.object(forKey: UserDefaultsKeys.repeatRate) == nil {
            defaults?.set(DefaultValues.repeatRate, forKey: UserDefaultsKeys.repeatRate)
        }
        // 활성화 드래그 거리
        if defaults?.object(forKey: UserDefaultsKeys.cursorActiveDistance) == nil {
            defaults?.set(DefaultValues.cursorActiveDistance, forKey: UserDefaultsKeys.cursorActiveDistance)
        }
        // 이동 드래그 간격
        if defaults?.object(forKey: UserDefaultsKeys.cursorMoveInterval) == nil {
            defaults?.set(DefaultValues.cursorMoveInterval, forKey: UserDefaultsKeys.cursorMoveInterval)
        }
        
        /* 외형 설정 */
        // 키보드 높이
        if defaults?.object(forKey: UserDefaultsKeys.keyboardHeight) == nil {
            defaults?.set(DefaultValues.keyboardHeight, forKey: UserDefaultsKeys.keyboardHeight)
        }
        // 숫자 키패드 활성화
        if defaults?.object(forKey: UserDefaultsKeys.isNumericKeypadEnabled) == nil {
            defaults?.set(DefaultValues.isNumericKeypadEnabled, forKey: UserDefaultsKeys.isNumericKeypadEnabled)
        }
        // 한 손 키보드 활성화
        if defaults?.object(forKey: UserDefaultsKeys.isOneHandedKeyboardEnabled) == nil {
            defaults?.set(DefaultValues.isOneHandedKeyboardEnabled, forKey: UserDefaultsKeys.isOneHandedKeyboardEnabled)
        }
        // 한 손 키보드 너비
        if defaults?.object(forKey: UserDefaultsKeys.oneHandedKeyboardWidth) == nil {
            defaults?.set(DefaultValues.oneHandedKeyboardWidth, forKey: UserDefaultsKeys.oneHandedKeyboardWidth)
        }
        
        /* 기타 설정 */
        // 키보드 전환 버튼(􀆪) 표시 설정용
        if defaults?.object(forKey: UserDefaultsKeys.needsInputModeSwitchKey) == nil {
            defaults?.set(DefaultValues.needsInputModeSwitchKey, forKey: UserDefaultsKeys.needsInputModeSwitchKey)
        }
        // 한 손 키보드 저장용
        if defaults?.object(forKey: UserDefaultsKeys.currentOneHandedKeyboard) == nil {
            defaults?.set(DefaultValues.currentOneHandedKeyboard, forKey: UserDefaultsKeys.currentOneHandedKeyboard)
        }
        // 온보딩 여부
        if defaults?.object(forKey: UserDefaultsKeys.isOnboarding) == nil {
            defaults?.set(DefaultValues.isOnboarding, forKey: UserDefaultsKeys.isOnboarding)
        }
        // 앱의 특정 기능 또는 키보드를 실행한 횟수
        if defaults?.object(forKey: UserDefaultsKeys.reviewCounter) == nil {
            defaults?.set(DefaultValues.reviewCounter, forKey: UserDefaultsKeys.reviewCounter)
        }
        // 마지막으로 리뷰를 요청한 빌드
        if defaults?.object(forKey: UserDefaultsKeys.lastBuildPromptedForReview) == nil {
            defaults?.set(DefaultValues.lastBuildPromptedForReview, forKey: UserDefaultsKeys.lastBuildPromptedForReview)
        }
    }
}
