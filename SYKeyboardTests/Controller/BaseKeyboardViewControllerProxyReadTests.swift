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
        controller.proxy.resetReadCounts()

        controller.viewWillDisappear(false)

        #expect(controller.proxy.contextReadCount == 0)
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
        controller.proxy.resetReadCounts()

        controller.viewWillDisappear(false)

        #expect(controller.proxy.contextReadCount == 0)
    }

    @Test("수식 모드가 아닌 후보 갱신 알림은 텍스트 프록시를 읽지 않음")
    func testNonMathSuggestionUpdateDoesNotReadProxy() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.resetReadCounts()

        // 후보 갱신 알림은 production 연결(`suggestionBarView.suggestionDelegate`)이 가리키는 Coordinator가 받는다.
        // 넘기는 controller는 표시 분기에만 쓰인다. 하이라이트는 VC 자신의 controller(기본 nGram 모드)를 본다
        let bar = (controller.view as! KeyboardView).suggestionBarView
        let suggestionDelegate = bar.suggestionDelegate as? SuggestionControllerDelegate
        #expect(suggestionDelegate != nil)
        suggestionDelegate?.suggestionController(
            SuggestionController(),
            didUpdateCurrentWord: "안녕",
            suggestions: ["안녕하세요"]
        )

        #expect(controller.proxy.contextReadCount == 0)
    }

    @Test("textDidChange 한 번에 같은 프록시 값을 두 번 읽지 않음")
    func testTextDidChangeReadsEachProxyValueAtMostOnce() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.resetReadCounts()

        controller.textDidChange(nil)

        let readCounts = controller.proxy.readCounts
        #expect(readCounts.values.allSatisfy { $0 <= 1 }, "\(readCounts)")
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
        #expect(controller.proxy.readCount(of: "keyboardType") == 1)
        #expect(controller.proxy.readCount(of: "returnKeyType") == 1)
    }

    @Test("textWillChange 한 번에 같은 프록시 값을 두 번 읽지 않음")
    func testTextWillChangeReadsEachProxyValueAtMostOnce() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.resetReadCounts()

        controller.textWillChange(nil)

        let readCounts = controller.proxy.readCounts
        #expect(readCounts.values.allSatisfy { $0 <= 1 }, "\(readCounts)")
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
        #expect(controller.proxy.readCount(of: "returnKeyType") == 1)
    }

    @Test("textWillChange에서 읽은 값을 textDidChange가 다시 읽음")
    func testTextDidChangeRereadsValuesReadInTextWillChange() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.textWillChange(nil)
        controller.proxy.resetReadCounts()
        controller.proxy.beforeInput = "바뀐 문맥"

        controller.textDidChange(nil)

        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
    }

    @Test("keyboardType이 바뀐 textDidChange는 새 값으로 trait 변경 훅을 한 번 부름")
    func testKeyboardTypeChangeCallsTraitHookOnceWithNewValue() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.textDidChange(nil)
        controller.proxy.keyboardType = .emailAddress

        controller.textDidChange(nil)

        #expect(controller.keyboardTypesAtTraitChange == [.emailAddress])
        #expect(controller.oldKeyboardType == .emailAddress)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestProxyReadViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let proxy = CountingTextDocumentProxy()

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

    private(set) var keyboardTypesAtTraitChange: [UIKeyboardType?] = []

    override func inputTraitsDidChange() {
        keyboardTypesAtTraitChange.append(textDocument.keyboardType)
    }
}
