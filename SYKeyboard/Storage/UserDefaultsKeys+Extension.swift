//
//  UserDefaultsKeys+Extension.swift
//  SYKeyboard
//
//  Created by 서동환 on 3/10/26.
//

import SYKeyboardCore

extension UserDefaultsKeys {
    /// 온보딩 여부
    static let isOnboarding = "isOnboarding"
    /// 앱의 특정 기능 또는 키보드를 실행한 횟수
    static let reviewCounter = "reviewCounter"
    /// 마지막으로 리뷰를 요청한 빌드
    static let lastBuildPromptedForReview = "lastBuildPromptedForReview"
}
