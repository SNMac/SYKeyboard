//
//  BaseKeyboardViewControllerSuggestionClipboardBehaviorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

/// #184 추출 전 동작을 고정한다. 후보 바·클립보드 패널의 delegate 호출은 production 연결(`suggestionDelegate`, `delegate`)을 거친다.
/// Coordinator로 옮겨지는 멤버(`isClipboardPanelVisible` 등)는 참조하지 않는다
@Suite("BaseKeyboardViewController 후보 선택·클립보드 동작 고정", .sharedUserDefaults)
@MainActor
struct BaseKeyboardViewControllerSuggestionClipboardBehaviorTests {

    @Test("수식 후보 1번 칸 탭은 결과만 삽입")
    func testMathResultSuggestionTapInsertsResult() {
        let settings = UserDefaultsManager.shared
        let oldPredictive = settings.isPredictiveTextEnabled
        let oldMath = settings.isShowMathResultsEnabled
        settings.isPredictiveTextEnabled = true
        settings.isShowMathResultsEnabled = true
        defer {
            settings.isPredictiveTextEnabled = oldPredictive
            settings.isShowMathResultsEnabled = oldMath
        }

        let controller = TestBehaviorViewController()
        controller.proxy.beforeInput = "3 - 1 ="
        controller.loadViewIfNeeded()
        controller.textDidChange(nil)
        let bar = controller.suggestionBar

        bar.suggestionDelegate?.suggestionBar(bar, didSelectSuggestionAt: 1)

        #expect(controller.proxy.writes == ["insertText(2)"])
    }

    @Test("수식 후보 탭의 프록시 문맥 읽기 횟수")
    func testMathResultSuggestionTapContextReadCount() {
        let settings = UserDefaultsManager.shared
        let oldPredictive = settings.isPredictiveTextEnabled
        let oldMath = settings.isShowMathResultsEnabled
        settings.isPredictiveTextEnabled = true
        settings.isShowMathResultsEnabled = true
        defer {
            settings.isPredictiveTextEnabled = oldPredictive
            settings.isShowMathResultsEnabled = oldMath
        }

        let controller = TestBehaviorViewController()
        controller.proxy.beforeInput = "3 - 1 ="
        controller.loadViewIfNeeded()
        controller.textDidChange(nil)
        let bar = controller.suggestionBar
        controller.proxy.resetReadCounts()

        bar.suggestionDelegate?.suggestionBar(bar, didSelectSuggestionAt: 1)

        // 추출 전 측정값(2026-10-08, c68a3a1f): 8. 후보 탭 처리와 뒤따르는 후보 갱신이 읽는 앞·뒤 문맥과 선택 텍스트의 합이다
        #expect(controller.proxy.contextReadCount == 8)
    }

    // 패널 열고 닫기는 ClipboardHistoryCoordinatorTests가 소유한다. 여기서는 클립보드 버튼 → 패널 표시 → 자판 숨김 연결과
    // textWillChange가 패널을 닫는 VC 동기화만 본다 (docs/adr/0003)
    @Test("클립보드 버튼 탭은 패널을 열고 자판을 숨기며 textWillChange는 열린 패널을 닫음")
    func testClipboardButtonOpensPanelAndTextWillChangeClosesIt() {
        let settings = UserDefaultsManager.shared
        let oldClipboard = settings.isClipboardHistoryEnabled
        settings.isClipboardHistoryEnabled = false
        defer { settings.isClipboardHistoryEnabled = oldClipboard }

        let controller = TestBehaviorViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar
        bar.suggestionDelegate?.suggestionBarDidTapClipboard(bar)
        #expect(controller.clipboardHistoryPanelView.isHidden == false)
        #expect(controller.primaryView.isHidden)

        controller.textWillChange(nil)

        #expect(controller.clipboardHistoryPanelView.isHidden)
        #expect(controller.primaryView.isHidden == false)
    }

    @Test("클립보드 텍스트 항목 탭은 한 번 삽입하고 패널을 닫음")
    func testClipboardTextItemTapInsertsAndClosesPanel() {
        let settings = UserDefaultsManager.shared
        let oldClipboard = settings.isClipboardHistoryEnabled
        settings.isClipboardHistoryEnabled = false
        defer { settings.isClipboardHistoryEnabled = oldClipboard }

        let controller = TestBehaviorViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar
        bar.suggestionDelegate?.suggestionBarDidTapClipboard(bar)
        let panel = controller.clipboardHistoryPanelView
        // 항목 탭은 App Group 저장소에 기록되므로 고유한 텍스트를 쓰고 끝나면 지운다
        let text = "테스트-\(UUID().uuidString)"
        panel.configure(state: .items([ClipboardHistoryItem(text: text, createdAt: Date())]))
        defer {
            if let store = controller.clipboardHistoryStore {
                store.remove(ids: Set(store.load().filter { $0.text == text }.map(\.id)))
            }
        }

        panel.delegate?.clipboardPanel(panel, didSelectItemAt: 0)

        #expect(controller.proxy.writes == ["insertText(\(text))"])
        #expect(controller.clipboardHistoryPanelView.isHidden)
        #expect(controller.primaryView.isHidden == false)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestBehaviorViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let proxy = CountingTextDocumentProxy()

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        primaryView
    }

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }

    /// `loadView`가 `view`에 넣는 `KeyboardView`의 후보 바. VC의 `suggestionBarView`는 private이라 뷰 계층으로 얻는다
    var suggestionBar: SuggestionBarView {
        (view as! KeyboardView).suggestionBarView
    }

    init() {
        super.init(language: "ko-KR")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateKeyboardType() {}
}
