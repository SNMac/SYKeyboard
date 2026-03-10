//
//  DefaultValues+Extension.swift
//  SYKeyboard
//
//  Created by 서동환 on 3/10/26.
//

import SYKeyboardCore

extension DefaultValues {
    /// 온보딩 여부 기본값
    static let isOnboarding: Bool = true
    /// 앱의 특정 기능 또는 키보드를 실행한 횟수 기본값
    static let reviewCounter: Int = 0
    /// 마지막으로 리뷰를 요청한 빌드 기본값
    static let lastBuildPromptedForReview: String = ""
}
