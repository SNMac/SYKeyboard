//
//  UserDefaultsManager+Extension.swift
//  SYKeyboard
//
//  Created by 서동환 on 3/10/26.
//

import SYKeyboardCore

extension UserDefaultsManager {
    /// 온보딩 여부
    var isOnboarding: Bool {
        get { storage.bool(forKey: UserDefaultsKeys.isOnboarding) }
        set { storage.set(newValue, forKey: UserDefaultsKeys.isOnboarding) }
    }

    /// 앱의 특정 기능 또는 키보드를 실행한 횟수
    var reviewCounter: Int {
        get { storage.integer(forKey: UserDefaultsKeys.reviewCounter) }
        set { storage.set(newValue, forKey: UserDefaultsKeys.reviewCounter) }
    }

    /// 마지막으로 리뷰를 요청한 빌드
    var lastBuildPromptedForReview: String {
        get { storage.string(forKey: UserDefaultsKeys.lastBuildPromptedForReview) ?? DefaultValues.lastBuildPromptedForReview }
        set { storage.set(newValue, forKey: UserDefaultsKeys.lastBuildPromptedForReview) }
    }
}
