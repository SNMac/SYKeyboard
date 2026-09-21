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

@Suite("UserDefaults 기본값 계약 검증", .serialized, .sharedUserDefaults)
struct UserDefaultsContractTests {

    @Test("자동 대문자는 저장값이 없으면 true를 반환하고 공유 저장소 키를 유지")
    func testAutoCapitalizationDefaultFallback() {
        let key = UserDefaultsKeys.isAutoCapitalizationEnabled

        withoutStoredValue(forKey: key) {
            #expect(key == "isAutoCapitalizationEnabled")
            #expect(DefaultValues.isAutoCapitalizationEnabled == true)
            #expect(UserDefaultsManager.shared.isAutoCapitalizationEnabled == true)
        }
    }

    @Test("Smart Punctuation은 저장값이 없으면 true를 반환하고 공유 저장소 키를 유지")
    func testSmartPunctuationDefaultFallbackAndKey() {
        let key = UserDefaultsKeys.isSmartPunctuationEnabled

        withoutStoredValue(forKey: key) {
            #expect(key == "isSmartPunctuationEnabled")
            #expect(DefaultValues.isSmartPunctuationEnabled == true)
            #expect(UserDefaultsManager.shared.isSmartPunctuationEnabled == true)
        }
    }

    @Test("수식 결과 표시는 저장값이 없으면 true를 반환하고 공유 저장소 키를 유지")
    func testShowMathResultsDefaultFallbackAndKey() {
        let key = UserDefaultsKeys.isShowMathResultsEnabled

        withoutStoredValue(forKey: key) {
            #expect(key == "isShowMathResultsEnabled")
            #expect(DefaultValues.isShowMathResultsEnabled == true)
            #expect(UserDefaultsManager.shared.isShowMathResultsEnabled == true)
        }
    }

    @Test("나랏글 점 표기는 저장값이 없으면 false를 반환하고 공유 저장소 키를 유지")
    func testNaratgeulDotLabelDefaultFallbackAndKey() {
        let key = UserDefaultsKeys.isNaratgeulDotLabelEnabled

        withoutStoredValue(forKey: key) {
            #expect(key == "isNaratgeulDotLabelEnabled")
            #expect(DefaultValues.isNaratgeulDotLabelEnabled == false)
            #expect(UserDefaultsManager.shared.isNaratgeulDotLabelEnabled == false)
        }
    }

    @Test("숫자 행 표시는 저장값이 없으면 false를 반환하고 공유 저장소 키를 유지")
    func testShowsNumberRowDefaultFallbackAndKey() {
        let key = UserDefaultsKeys.showsNumberRow

        withoutStoredValue(forKey: key) {
            #expect(key == "showsNumberRow")
            #expect(DefaultValues.showsNumberRow == false)
            #expect(UserDefaultsManager.shared.showsNumberRow == false)
        }
    }

    @Test("스페이스 하단 배치는 저장값이 없으면 false를 반환하고 공유 저장소 키를 유지")
    func testBottomSpaceDefaultFallbackAndKey() {
        let key = UserDefaultsKeys.isBottomSpaceEnabled

        withoutStoredValue(forKey: key) {
            #expect(key == "isBottomSpaceEnabled")
            #expect(DefaultValues.isBottomSpaceEnabled == false)
            #expect(UserDefaultsManager.shared.isBottomSpaceEnabled == false)
        }
    }

    @Test("한영 통합 키보드 마지막 mode는 기본값과 raw value 계약을 유지")
    func testLastHangeulEnglishLanguageModeDefaultAndRawValueRoundTrip() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.lastHangeulEnglishLanguageMode

        withoutStoredValue(forKey: key) {
            #expect(key == "lastHangeulEnglishLanguageMode")
            #expect(DefaultValues.lastHangeulEnglishLanguageMode == .hangeul)
            #expect(UserDefaultsManager.shared.lastHangeulEnglishLanguageMode == .hangeul)

            UserDefaultsManager.shared.lastHangeulEnglishLanguageMode = .english

            #expect(storage.string(forKey: key) == "english")
            #expect(UserDefaultsManager.shared.lastHangeulEnglishLanguageMode == .english)
        }
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

    @Test("앱 전용 온보딩 상태는 저장값이 없으면 true를 반환")
    func testAppOnboardingDefaultFallback() {
        let suiteName = "UserDefaultsContractTests-\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        defer { storage.removePersistentDomain(forName: suiteName) }

        let manager = AppUserDefaultsManager(storage: storage)

        #expect(AppDefaultValues.isOnboarding == true)
        #expect(manager.isOnboarding == true)
    }

    @Test("앱 전용 저장소 키는 기존 문자열을 유지")
    func testAppUserDefaultsKeysKeepExistingRawValues() {
        #expect(AppUserDefaultsKeys.isOnboarding == "isOnboarding")
        #expect(AppUserDefaultsKeys.reviewCounter == "reviewCounter")
        #expect(AppUserDefaultsKeys.lastBuildPromptedForReview == "lastBuildPromptedForReview")
    }

    @Test("KeyboardExtensionLocalStateStore는 주입한 저장소에만 닫힘 상태를 기록")
    func testKeyboardExtensionLocalStateStoreUsesInjectedStorage() {
        let suiteName = "KeyboardExtensionLocalStateStoreTests-\(UUID().uuidString)"
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

        #expect(DefaultValues.isRequestFullAccessOverlayClosed == false)
        #expect(store.isClosed == false)

        store.isClosed = true

        #expect(localStorage.bool(forKey: key) == true)
        #expect(sharedStorage.object(forKey: key) == nil)
    }

    @Test("글자 열 너비 배율은 저장값이 없으면 1.0을 반환하고 공유 저장소 키를 유지")
    func testLetterColumnWidthMultiplierDefaultFallbackAndKey() {
        let key = UserDefaultsKeys.letterColumnWidthMultiplier

        withoutStoredValue(forKey: key) {
            #expect(key == "letterColumnWidthMultiplier")
            #expect(DefaultValues.letterColumnWidthMultiplier == 1.0)
            #expect(UserDefaultsManager.shared.letterColumnWidthMultiplier == 1.0)
        }
    }

    @Test("클립보드 기록은 저장값이 없으면 false를 반환하고 공유 저장소 키를 유지")
    func testClipboardHistoryDefaultFallbackAndKey() {
        let key = UserDefaultsKeys.isClipboardHistoryEnabled

        withoutStoredValue(forKey: key) {
            #expect(key == "isClipboardHistoryEnabled")
            #expect(DefaultValues.isClipboardHistoryEnabled == false)
            #expect(UserDefaultsManager.shared.isClipboardHistoryEnabled == false)
        }
    }

    @Test("이미지 클립보드 기록은 저장값이 없으면 true를 반환하고 공유 저장소 키를 유지")
    func testClipboardImageHistoryDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isClipboardImageHistoryEnabled

        withoutStoredValue(forKey: key) {
            #expect(key == "isClipboardImageHistoryEnabled")
            #expect(DefaultValues.isClipboardImageHistoryEnabled == true)
            #expect(UserDefaultsManager.shared.isClipboardImageHistoryEnabled == true)

            UserDefaultsManager.shared.isClipboardImageHistoryEnabled = false

            #expect(storage.bool(forKey: key) == false)
            #expect(UserDefaultsManager.shared.isClipboardImageHistoryEnabled == false)
        }
    }

    @Test("마지막 pasteboard changeCount는 저장값이 없으면 -1을 반환하고 공유 저장소 키를 유지")
    func testLastSeenPasteboardChangeCountDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.lastSeenPasteboardChangeCount

        withoutStoredValue(forKey: key) {
            #expect(key == "lastSeenPasteboardChangeCount")
            #expect(DefaultValues.lastSeenPasteboardChangeCount == -1)
            #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == -1)

            UserDefaultsManager.shared.lastSeenPasteboardChangeCount = 7

            #expect(storage.integer(forKey: key) == 7)
            #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == 7)
        }
    }

    @Test("예산 초과로 건너뛴 pasteboard changeCount는 저장값이 없으면 -1을 반환하고 공유 저장소 키를 유지")
    func testBudgetSkippedPasteboardChangeCountDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.budgetSkippedPasteboardChangeCount

        withoutStoredValue(forKey: key) {
            #expect(key == "budgetSkippedPasteboardChangeCount")
            #expect(DefaultValues.budgetSkippedPasteboardChangeCount == -1)
            #expect(UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount == -1)

            UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount = 9

            #expect(storage.integer(forKey: key) == 9)
            #expect(UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount == 9)
        }
    }
}

private extension UserDefaultsContractTests {
    /// 공유 저장소에서 저장값을 지운 상태로 `body`를 실행하고 원래 값을 되돌린다
    func withoutStoredValue(forKey key: String, _ body: () -> Void) {
        let storage = UserDefaultsManager.shared.storage
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        body()
    }

    func restore(_ value: Any?, forKey key: String, in storage: UserDefaults) {
        if let value {
            storage.set(value, forKey: key)
        } else {
            storage.removeObject(forKey: key)
        }
    }
}
