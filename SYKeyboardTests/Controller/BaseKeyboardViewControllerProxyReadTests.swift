//
//  BaseKeyboardViewControllerProxyReadTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/7/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

/// 문서 상태 교체와 겹친 프록시 읽기는 크래시하므로, 결과에 쓰이지 않는 읽기가 없는지 확인한다
@Suite("BaseKeyboardViewController 불필요한 텍스트 프록시 읽기", .sharedUserDefaults)
@MainActor
struct BaseKeyboardViewControllerProxyReadTests {

    @Test("viewWillDisappear는 텍스트 프록시 문맥을 읽지 않음")
    func testViewWillDisappearDoesNotReadDocumentContext() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.readCount = 0

        controller.viewWillDisappear(false)

        #expect(controller.proxy.readCount == 0)
    }

    @Test("undo 기록이 남은 채 키보드가 사라져도 텍스트 프록시 문맥을 읽지 않음")
    func testViewWillDisappearWithUndoHistoryDoesNotReadDocumentContext() {
        let oldIsUndoRedoEnabled = UserDefaultsManager.shared.isUndoRedoEnabled
        UserDefaultsManager.shared.isUndoRedoEnabled = true
        defer { UserDefaultsManager.shared.isUndoRedoEnabled = oldIsUndoRedoEnabled }

        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        // 입력으로 아직 확정되지 않은 undo 기록을 만든다. 실제 크래시는 이 상태에서 키보드가 내려갈 때 났다
        controller.insertText("가")
        controller.proxy.readCount = 0

        controller.viewWillDisappear(false)

        #expect(controller.proxy.readCount == 0)
    }

    @Test("수식 모드가 아닌 후보 갱신 알림은 텍스트 프록시를 읽지 않음")
    func testNonMathSuggestionUpdateDoesNotReadProxy() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.readCount = 0

        // 넘기는 controller는 표시 분기에만 쓰인다. 하이라이트는 VC 자신의 controller(기본 nGram 모드)를 본다
        controller.suggestionController(
            SuggestionController(),
            didUpdateCurrentWord: "안녕",
            suggestions: ["안녕하세요"]
        )

        #expect(controller.proxy.readCount == 0)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestProxyReadViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let proxy = ReadCountingTextDocumentProxy()

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

/// 문맥·선택 텍스트 읽기 횟수를 세는 프록시
private final class ReadCountingTextDocumentProxy: NSObject, UITextDocumentProxy {
    var readCount = 0

    var documentContextBeforeInput: String? {
        readCount += 1
        return "안녕"
    }

    var documentContextAfterInput: String? {
        readCount += 1
        return nil
    }

    var selectedText: String? {
        readCount += 1
        return nil
    }

    var documentInputMode: UITextInputMode? { nil }
    var documentIdentifier: UUID { UUID() }
    var hasText: Bool { true }

    func adjustTextPosition(byCharacterOffset offset: Int) {}
    func setMarkedText(_ markedText: String, selectedRange: NSRange) {}
    func unmarkText() {}
    func insertText(_ text: String) {}
    func deleteBackward() {}
}
