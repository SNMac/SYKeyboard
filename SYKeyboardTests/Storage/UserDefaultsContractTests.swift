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

@Suite("UserDefaults 기본값 계약 검증", .serialized)
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

    @Test("Smart Punctuation은 저장값이 없으면 true를 반환하고 공유 저장소 키를 유지")
    func testSmartPunctuationDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isSmartPunctuationEnabled
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "isSmartPunctuationEnabled")
        #expect(DefaultValues.isSmartPunctuationEnabled == true)
        #expect(UserDefaultsManager.shared.isSmartPunctuationEnabled == true)
    }

    @Test("수식 결과 표시는 저장값이 없으면 true를 반환하고 공유 저장소 키를 유지")
    func testShowMathResultsDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isShowMathResultsEnabled
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "isShowMathResultsEnabled")
        #expect(DefaultValues.isShowMathResultsEnabled == true)
        #expect(UserDefaultsManager.shared.isShowMathResultsEnabled == true)
    }

    @Test("한영 통합 키보드 마지막 mode는 기본값과 raw value 계약을 유지")
    func testLastHangeulEnglishLanguageModeDefaultAndRawValueRoundTrip() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.lastHangeulEnglishLanguageMode
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "lastHangeulEnglishLanguageMode")
        #expect(DefaultValues.lastHangeulEnglishLanguageMode == .hangeul)
        #expect(UserDefaultsManager.shared.lastHangeulEnglishLanguageMode == .hangeul)

        UserDefaultsManager.shared.lastHangeulEnglishLanguageMode = .english

        #expect(storage.string(forKey: key) == "english")
        #expect(UserDefaultsManager.shared.lastHangeulEnglishLanguageMode == .english)
    }

    @Test("한영 통합 키보드 마지막 mode의 손상 raw value는 기본값으로 fallback")
    func testInvalidLastHangeulEnglishLanguageModeUsesDefault() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.lastHangeulEnglishLanguageMode
        let originalValue = storage.object(forKey: key)

        storage.set("invalid", forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(UserDefaultsManager.shared.lastHangeulEnglishLanguageMode == .hangeul)
    }

    @Test("앱 전용 온보딩 상태는 저장값이 없으면 앱 기본값을 반환")
    func testAppOnboardingDefaultFallback() {
        let suiteName = "UserDefaultsContractTests-\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        defer { storage.removePersistentDomain(forName: suiteName) }

        let manager = AppUserDefaultsManager(storage: storage)

        #expect(manager.isOnboarding == AppDefaultValues.isOnboarding)
    }

    @Test("앱 전용 저장소 키는 기존 문자열을 유지")
    func testAppUserDefaultsKeysKeepExistingRawValues() {
        #expect(AppUserDefaultsKeys.isOnboarding == "isOnboarding")
        #expect(AppUserDefaultsKeys.reviewCounter == "reviewCounter")
        #expect(AppUserDefaultsKeys.lastBuildPromptedForReview == "lastBuildPromptedForReview")
    }

    @Test("KeyboardExtensionLocalStateStore는 주입한 저장소에만 닫힘 상태를 기록")
    func testKeyboardExtensionLocalStateStoreUsesInjectedStorage() {
        let suiteName = "RequestFullAccessOverlayStateTests-\(UUID().uuidString)"
        let localStorage = UserDefaults(suiteName: suiteName)!
        let sharedStorage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isRequestFullAccessOverlayClosed
        let originalSharedValue = sharedStorage.object(forKey: key)

        sharedStorage.removeObject(forKey: key)
        defer {
            localStorage.removePersistentDomain(forName: suiteName)
            restore(originalSharedValue, forKey: key, in: sharedStorage)
        }

        let store = KeyboardExtensionLocalStateStore(storage: localStorage)

        #expect(store.isClosed == DefaultValues.isRequestFullAccessOverlayClosed)

        store.isClosed = true

        #expect(localStorage.bool(forKey: key) == true)
        #expect(sharedStorage.object(forKey: key) == nil)
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
