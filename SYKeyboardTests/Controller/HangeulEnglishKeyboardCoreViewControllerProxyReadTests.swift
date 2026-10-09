//
//  HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/9/26.
//

import Testing
import UIKit

@testable import HangeulEnglishKeyboardCore
@testable import SYKeyboardCore

/// 한영 통합 VC가 `super.textWillChange` 뒤에서 읽는 값도 같은 콜백 범위에서 한 번만 읽는지 확인한다
@Suite("HangeulEnglishKeyboardCoreViewController 텍스트 프록시 읽기", .sharedUserDefaults)
@MainActor
struct HangeulEnglishKeyboardCoreViewControllerProxyReadTests {

    @Test("영어 모드 textWillChange는 shift 자동 대문자 판정까지 같은 프록시 값을 한 번만 읽음")
    func testTextWillChangeReadsShiftContextOnceInEnglishMode() {
        withLastLanguageMode(.english) {
            let controller = TestHangeulEnglishProxyReadViewController()
            controller.loadViewIfNeeded()
            controller.proxy.resetReadCounts()

            controller.textWillChange(nil)

            #expect(controller.proxy.readCount(of: "autocapitalizationType") == 1)
            #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
        }
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestHangeulEnglishProxyReadViewController: HangeulEnglishKeyboardCoreViewController {
    let proxy = CountingTextDocumentProxy()

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }
}

/// VC `init()`이 읽는 마지막 언어를 바꾸고, body가 끝나면 원래 저장값으로 되돌린다.
/// 한/A 전환이 `persist: true`로 다시 저장하므로 테스트 본문 전체를 감싼다
@MainActor
private func withLastLanguageMode(_ mode: HangeulEnglishLanguageMode, _ body: () -> Void) {
    let storage = UserDefaultsManager.shared.storage
    let key = UserDefaultsKeys.lastHangeulEnglishLanguageMode
    let original = storage.object(forKey: key)
    defer {
        if let original {
            storage.set(original, forKey: key)
        } else {
            storage.removeObject(forKey: key)
        }
    }

    UserDefaultsManager.shared.lastHangeulEnglishLanguageMode = mode
    body()
}
