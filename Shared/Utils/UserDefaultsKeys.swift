//
//  UserDefaultsKeys.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/15/25.
//

import Foundation

enum UserDefaultsKeys: String {
    /* 피드백 설정 */
    /// 소리 피드백
    case isSoundFeedbackEnabled
    /// 햅틱 피드백
    case isHapticFeedbackEnabled
    
    /* 입력 설정 */
    /// 텍스트 대치
    case isTextReplacementEnabled
    /// 스페이스/리턴 입력 후 한글 키보드로 변경
    case isAutoChangeToHangeulEnabled
    
    /* 입력 설정 -> 속도/커서 설정 */
    /// 반복 지연 시간
    case longPressDuration
    /// 키 반복 속도
    case repeatRate
    /// 활성화 드래그 거리
    case cursorActiveDistance
    /// 이동 드래그 간격
    case cursorMoveInterval
    
    /* 외형 설정 */
    /// 키보드 높이
    case keyboardHeight
    /// 숫자 키패드 활성화
    case isNumericKeypadEnabled
    /// 한 손 키보드 활성화
    case isOneHandedKeyboardEnabled
    /// 한 손 키보드 너비
    case oneHandedKeyboardWidth
    
    /* 기타 설정 */
    /// 키보드 전환 버튼(􀆪) 표시 설정용
    case needsInputModeSwitchKey
    /// 한 손 키보드 저장용 (0 = 왼쪽, 1 = 가운데, 2 = 오른쪽)
    case currentOneHandedKeyboard
    /// 화면 너비 저장용
    case screenWidth
    /// 온보딩 여부
    case isOnboarding
    /// 앱의 특정 기능 또는 키보드를 실행한 횟수
    case reviewCounter
    /// 마지막으로 리뷰를 요청한 빌드
    case lastBuildPromptedForReview
}
