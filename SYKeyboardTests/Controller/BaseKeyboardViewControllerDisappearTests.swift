//
//  BaseKeyboardViewControllerDisappearTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/7/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("BaseKeyboardViewController 키보드가 사라질 때 텍스트 프록시 접근", .sharedUserDefaults)
@MainActor
struct BaseKeyboardViewControllerDisappearTests {

    @Test("viewWillDisappear는 텍스트 프록시 문맥을 읽지 않음")
    func testViewWillDisappearDoesNotReadDocumentContext() {
        let controller = TestDisappearViewController()
        controller.loadViewIfNeeded()
        controller.proxy.contextReadCount = 0

        controller.viewWillDisappear(false)

        #expect(controller.proxy.contextReadCount == 0)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestDisappearViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let proxy = ContextCountingTextDocumentProxy()

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        primaryView
    }

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }

    init() {
        super.init(language: "ko-KR")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateKeyboardType() {}
}

/// 문맥 읽기 횟수를 세는 프록시. 문서 상태 교체와 겹친 읽기가 크래시하므로 읽기 자체를 센다
private final class ContextCountingTextDocumentProxy: NSObject, UITextDocumentProxy {
    var contextReadCount = 0

    var documentContextBeforeInput: String? {
        contextReadCount += 1
        return "안녕"
    }

    var documentContextAfterInput: String? {
        contextReadCount += 1
        return nil
    }

    var selectedText: String? { nil }
    var documentInputMode: UITextInputMode? { nil }
    var documentIdentifier: UUID { UUID() }
    var hasText: Bool { true }

    func adjustTextPosition(byCharacterOffset offset: Int) {}
    func setMarkedText(_ markedText: String, selectedRange: NSRange) {}
    func unmarkText() {}
    func insertText(_ text: String) {}
    func deleteBackward() {}
}
