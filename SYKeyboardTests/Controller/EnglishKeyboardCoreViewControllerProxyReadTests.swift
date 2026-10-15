//
//  EnglishKeyboardCoreViewControllerProxyReadTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import EnglishKeyboardCore
@testable import SYKeyboardCore

/// 하위 VC가 `super.textWillChange` 뒤에서 읽는 값도 같은 콜백 범위에서 한 번만 읽는지 확인한다
@Suite("EnglishKeyboardCoreViewController 텍스트 프록시 읽기", .sharedUserDefaults)
@MainActor
struct EnglishKeyboardCoreViewControllerProxyReadTests {

    @Test("textWillChange는 shift 자동 대문자 판정까지 같은 프록시 값을 한 번만 읽음")
    func testTextWillChangeReadsShiftContextOnce() {
        let controller = TestEnglishProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.resetReadCounts()

        controller.textWillChange(nil)

        #expect(controller.proxy.readCount(of: "autocapitalizationType") == 1)
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestEnglishProxyReadViewController: EnglishKeyboardCoreViewController {
    let proxy = CountingTextDocumentProxy()

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }
}
