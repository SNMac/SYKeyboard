//
//  PrimaryKeyButtonLabelTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 8/27/26.
//

import Foundation
import Testing
import UIKit

@testable import SYKeyboardCore

@MainActor
@Suite("나랏글 획·쌍 버튼 표기", .serialized)
struct PrimaryKeyButtonLabelTests {

    @Test("설정이 꺼져 있으면 기존 '획', '쌍' 표기를 유지")
    func testKeepsOriginalLabelsWhenDisabled() {
        withDotLabel(enabled: false) {
            #expect(makeButton(primary: "획", secondary: "획").primaryKeyListLabel.text == "획")
            #expect(makeButton(primary: "쌍", secondary: "쌍").primaryKeyListLabel.text == "쌍")
        }
    }

    @Test("설정이 켜져 있으면 '획'은 'ㆍ', '쌍'은 'ᆢ'로 표기")
    func testShowsDotLabelsWhenEnabled() {
        withDotLabel(enabled: true) {
            #expect(makeButton(primary: "획", secondary: "획").primaryKeyListLabel.text == "\u{318D}")
            #expect(makeButton(primary: "쌍", secondary: "쌍").primaryKeyListLabel.text == "\u{11A2}")
        }
    }

    @Test("표기를 바꿔도 입력 식별자는 '획', '쌍'을 유지")
    func testKeepsInputIdentifierWhenEnabled() {
        withDotLabel(enabled: true) {
            #expect(makeButton(primary: "획", secondary: "획").type.primaryKeyList == ["획"])
            #expect(makeButton(primary: "쌍", secondary: "쌍").type.primaryKeyList == ["쌍"])
        }
    }

    @Test("주 키와 코너 키가 같으면 표기 설정과 무관하게 코너 라벨을 숨김")
    func testHidesSecondaryLabelRegardlessOfDotLabelSetting() {
        for isEnabled in [false, true] {
            withDotLabel(enabled: isEnabled) {
                #expect(makeButton(primary: "획", secondary: "획").secondaryKeyLabel.text == "")
                #expect(makeButton(primary: "쌍", secondary: "쌍").secondaryKeyLabel.text == "")
            }
        }
    }

    @Test("표기 설정을 켜도 다른 키의 표기와 코너 라벨은 그대로 유지")
    func testDoesNotAffectOtherKeys() {
        withDotLabel(enabled: true) {
            let button = makeButton(primary: "ㄱ", secondary: "1")
            #expect(button.primaryKeyListLabel.text == "ㄱ")
            #expect(button.secondaryKeyLabel.text == "1")
        }
    }
}

// MARK: - Helper Methods

private extension PrimaryKeyButtonLabelTests {
    func makeButton(primary: String, secondary: String) -> PrimaryKeyButton {
        PrimaryKeyButton(keyboard: .naratgeul,
                         button: .keyButton(primary: [primary], secondary: secondary))
    }

    /// 공유 저장소의 표기 설정을 잠시 바꾸고 원래 값으로 되돌린다.
    func withDotLabel(enabled: Bool, _ body: () -> Void) {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isNaratgeulDotLabelEnabled
        let originalValue = storage.object(forKey: key)
        defer {
            if let originalValue {
                storage.set(originalValue, forKey: key)
            } else {
                storage.removeObject(forKey: key)
            }
        }

        storage.set(enabled, forKey: key)
        body()
    }
}
