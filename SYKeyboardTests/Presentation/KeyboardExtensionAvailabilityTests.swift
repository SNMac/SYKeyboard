//
//  KeyboardExtensionAvailabilityTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/19/26.
//

import Foundation
import Testing

@testable import SYKeyboard

@Suite("키보드 확장 활성화 확인 검증")
struct KeyboardExtensionAvailabilityTests {

    @Test("현재 앱의 키보드 확장이 AppleKeyboards에 있으면 활성화 상태")
    func testEnabledWhenCurrentKeyboardExtensionExists() {
        let (suiteName, userDefaults) = makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        userDefaults.set(
            [
                "ko_KR@sw=Korean",
                "com.example.SYKeyboard.keyboard",
            ],
            forKey: "AppleKeyboards"
        )

        let isEnabled = KeyboardExtensionAvailability.isEnabled(
            userDefaults: userDefaults,
            bundleIdentifier: "com.example.SYKeyboard"
        )

        #expect(isEnabled == true)
    }

    @Test("현재 앱의 키보드 확장이 AppleKeyboards에 없으면 비활성화 상태")
    func testDisabledWhenCurrentKeyboardExtensionDoesNotExist() {
        let (suiteName, userDefaults) = makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        userDefaults.set(
            [
                "ko_KR@sw=Korean",
                "com.example.OtherKeyboard.keyboard",
            ],
            forKey: "AppleKeyboards"
        )

        let isEnabled = KeyboardExtensionAvailability.isEnabled(
            userDefaults: userDefaults,
            bundleIdentifier: "com.example.SYKeyboard"
        )

        #expect(isEnabled == false)
    }

    @Test("AppleKeyboards 목록이 비어 있으면 비활성화 상태")
    func testDisabledWhenAppleKeyboardsEmpty() {
        let (suiteName, userDefaults) = makeUserDefaults()
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        userDefaults.set([], forKey: "AppleKeyboards")

        let isEnabled = KeyboardExtensionAvailability.isEnabled(
            userDefaults: userDefaults,
            bundleIdentifier: "com.example.SYKeyboard"
        )

        #expect(isEnabled == false)
    }

    private func makeUserDefaults() -> (suiteName: String, userDefaults: UserDefaults) {
        let suiteName = "KeyboardExtensionAvailabilityTests.\(UUID().uuidString)"
        return (suiteName, UserDefaults(suiteName: suiteName)!)
    }
}
