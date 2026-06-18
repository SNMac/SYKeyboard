//
//  UserDefaultsContractTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/18/26.
//

import Foundation
import Testing

import EnglishKeyboardCore
import SYKeyboardCore
@testable import SYKeyboard

@Suite("UserDefaults 기본값 계약 검증")
struct UserDefaultsContractTests {

    @Test("자동 대문자는 저장값이 없으면 선언된 기본값을 반환")
    func testAutoCapitalizationDefaultFallback() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isAutoCapitalizationEnabled
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(UserDefaultsManager.shared.isAutoCapitalizationEnabled == DefaultValues.isAutoCapitalizationEnabled)
    }

    @Test("앱 전용 온보딩 상태는 저장값이 없으면 앱 기본값을 반환")
    func testAppOnboardingDefaultFallback() {
        let storage = UserDefaults(suiteName: "UserDefaultsContractTests-\(UUID().uuidString)")!
        let manager = AppUserDefaultsManager(storage: storage)

        #expect(manager.isOnboarding == AppDefaultValues.isOnboarding)
    }

    @Test("앱 전용 저장소 키는 기존 문자열을 유지")
    func testAppUserDefaultsKeysKeepExistingRawValues() {
        #expect(AppUserDefaultsKeys.isOnboarding == "isOnboarding")
        #expect(AppUserDefaultsKeys.reviewCounter == "reviewCounter")
        #expect(AppUserDefaultsKeys.lastBuildPromptedForReview == "lastBuildPromptedForReview")
    }
}

private extension UserDefaultsContractTests {
    func restore(_ value: Any?, forKey key: String, in storage: UserDefaults) {
        if let value {
            storage.set(value, forKey: key)
        } else {
            storage.removeObject(forKey: key)
        }
    }
}
