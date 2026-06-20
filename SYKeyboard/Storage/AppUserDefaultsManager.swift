//
//  AppUserDefaultsManager.swift
//  SYKeyboard
//
//  Created by Codex on 6/18/26.
//

import Foundation

import SYKeyboardCore

/// 앱 전용 `UserDefaults` 상태를 관리합니다.
final class AppUserDefaultsManager {

    // MARK: - Properties

    /// 데이터를 저장할 `UserDefaults`
    let storage: UserDefaults

    // MARK: - Singleton Initializer

    static let shared = AppUserDefaultsManager()

    init(storage: UserDefaults = AppUserDefaultsManager.defaultStorage) {
        self.storage = storage
    }

    // MARK: - 앱 상태

    /// 온보딩 여부
    var isOnboarding: Bool {
        get {
            storage.object(forKey: AppUserDefaultsKeys.isOnboarding) as? Bool
            ?? AppDefaultValues.isOnboarding
        }
        set { storage.set(newValue, forKey: AppUserDefaultsKeys.isOnboarding) }
    }

    /// 앱의 특정 기능 또는 키보드를 실행한 횟수
    var reviewCounter: Int {
        get {
            storage.object(forKey: AppUserDefaultsKeys.reviewCounter) as? Int
            ?? AppDefaultValues.reviewCounter
        }
        set { storage.set(newValue, forKey: AppUserDefaultsKeys.reviewCounter) }
    }

    /// 마지막으로 리뷰를 요청한 빌드
    var lastBuildPromptedForReview: String {
        get {
            storage.string(forKey: AppUserDefaultsKeys.lastBuildPromptedForReview)
            ?? AppDefaultValues.lastBuildPromptedForReview
        }
        set { storage.set(newValue, forKey: AppUserDefaultsKeys.lastBuildPromptedForReview) }
    }
}

private extension AppUserDefaultsManager {
    static let defaultStorage: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
            fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
        }
        return userDefaults
    }()
}
