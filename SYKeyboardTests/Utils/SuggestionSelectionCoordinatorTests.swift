//
//  SuggestionSelectionCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("후보 선택 Coordinator", .sharedUserDefaults)
@MainActor
struct SuggestionSelectionCoordinatorTests {

    @Test("수식 모드에서 결과 삽입 action은 삭제 보류를 끊고 삽입 뒤 적용 훅과 갱신을 부름")
    func testMathInsertResultAction() {
        let fixture = makeFixture()
        fixture.service.currentMode = .mathExpression
        fixture.service.mathResultActionResult = .insertResult("5")

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 1)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions", "insertText(5)", "suggestionDidApply", "refreshSuggestions"])
    }

    @Test("수식 원문 확정은 후보만 비우고 적용 훅을 부르지 않음")
    func testMathConfirmOriginalOnlyClears() {
        let fixture = makeFixture()
        fixture.service.currentMode = .mathExpression
        fixture.service.mathResultActionResult = .confirmOriginal

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 0)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions"])
        #expect(fixture.service.calls.contains("clearSuggestions"))
    }

    @Test("n-gram 후보는 기준 텍스트가 공백으로 끝나지 않으면 앞에 공백을 넣음")
    func testNGramSuggestionInsertsLeadingSpace() {
        let fixture = makeFixture()
        fixture.service.currentMode = .nGram
        fixture.service.nGramSuggestionTextResult = "날씨"
        fixture.host.suggestionBaseText = "오늘"
        fixture.host.currentInputBuffer = "오늘"

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 0)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions", "insertText( )", "insertText(날씨)", "suggestionDidApply"])
        #expect(fixture.service.calls.last == "updateSuggestionsAfterNGramSelection(오늘, 오늘)")
    }

    @Test("n-gram 후보는 기준 텍스트가 공백으로 끝나면 바로 삽입")
    func testNGramSuggestionWithoutLeadingSpace() {
        let fixture = makeFixture()
        fixture.service.currentMode = .nGram
        fixture.service.nGramSuggestionTextResult = "날씨"
        fixture.host.suggestionBaseText = "오늘 "

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 0)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions", "insertText(날씨)", "suggestionDidApply"])
    }

    @Test("입력 중 0번 칸은 현재 단어를 학습·기록하고 후보를 비움")
    func testCurrentWordConfirmation() {
        let fixture = makeFixture()
        fixture.service.currentMode = .typing
        fixture.host.learnableWordText = "안녕"

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 0)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions"])
        #expect(fixture.service.learnedWords == ["안녕"])
        #expect(fixture.service.recordedWords == ["안녕"])
        #expect(fixture.service.calls.last == "clearSuggestions")
    }

    @Test("입력 중 1번 이상 칸은 현재 단어를 후보로 바꾸고 기록")
    func testInputBufferSuggestionReplacesCurrentWord() {
        let fixture = makeFixture()
        fixture.service.currentMode = .typing
        fixture.service.selectSuggestionResult = (deleteCount: 2, insertText: "안녕하세요")
        fixture.host.suggestionBaseText = "안녕"
        fixture.host.currentInputBuffer = "안녕"

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 2)

        #expect(fixture.service.selectSuggestionArguments.map(\.index) == [1])
        #expect(fixture.host.calls == [
            "interruptPendingDeleteInteractions",
            "replaceTextWithSmartSpacing(2, 안녕하세요)",
            "suggestionDidApply",
            "refreshSuggestions"
        ])
        #expect(fixture.service.recordedWords == ["안녕하세요"])
    }

    @Test("선택 텍스트가 있으면 선택 범위를 후보로 대치")
    func testSelectedTextSuggestionReplacesSelection() {
        let fixture = makeFixture()
        fixture.service.currentMode = .typing
        fixture.proxy.selected = "abc"
        fixture.service.selectSuggestionResult = (deleteCount: 0, insertText: "ABC")

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 1)

        #expect(fixture.service.selectSuggestionArguments.map(\.baseText) == ["abc"])
        #expect(fixture.host.calls == [
            "interruptPendingDeleteInteractions",
            "smartSpacedText(0, ABC)",
            "replaceSelectedText(abc, ABC)",
            "suggestionDidApply",
            "refreshSuggestions"
        ])
    }

    @Test("후보 길게 누르기는 삭제 가능한 단어가 있으면 확인 오버레이를 띄움")
    func testRemovalLongPressShowsConfirmation() {
        let fixture = makeFixture()
        fixture.service.removableSuggestionTextResult = "오늘"

        let began = fixture.coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)

        #expect(began)
        let overlay = fixture.host.overlayContainerView.subviews.compactMap { $0 as? DeleteConfirmOverlayView }.first
        #expect(overlay?.isHidden == false)

        overlay?.onCancel?()
        #expect(overlay?.isHidden == true)
        #expect(fixture.service.removedWords.isEmpty)
    }

    @Test("삭제 확인을 누르면 단어를 자동완성에서 지움")
    func testRemovalConfirmRemovesWord() {
        let fixture = makeFixture()
        fixture.service.removableSuggestionTextResult = "오늘"
        _ = fixture.coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)
        let overlay = fixture.host.overlayContainerView.subviews.compactMap { $0 as? DeleteConfirmOverlayView }.first

        overlay?.onConfirm?()

        #expect(fixture.service.removedWords == ["오늘"])
        #expect(overlay?.isHidden == true)
    }

    @Test("미리보기에서는 후보 길게 누르기와 클립보드 버튼이 동작하지 않음")
    func testPreviewBlocksRemovalAndClipboard() {
        let fixture = makeFixture()
        fixture.host.isPreviewMode = true
        fixture.service.removableSuggestionTextResult = "오늘"

        let began = fixture.coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)
        fixture.coordinator.suggestionBarDidTapClipboard(fixture.bar)

        #expect(began == false)
        #expect(fixture.host.calls.isEmpty)
    }

    @Test("undo·redo·클립보드 버튼은 host로 전달")
    func testToolbarButtonsForwardToHost() {
        let fixture = makeFixture()

        fixture.coordinator.suggestionBarDidTapUndo(fixture.bar)
        fixture.coordinator.suggestionBarDidTapRedo(fixture.bar)
        fixture.coordinator.suggestionBarDidTapClipboard(fixture.bar)

        #expect(fixture.host.calls == ["undoLastEdit", "redoLastEdit", "toggleClipboardPanel"])
    }

    @Test("trait 동기화는 autocorrection을 저장하고 수식 허용 여부를 반영")
    func testSynchronizeTextInputTraits() {
        let fixture = makeFixture()
        let settings = UserDefaultsManager.shared
        let oldMath = settings.isShowMathResultsEnabled
        settings.isShowMathResultsEnabled = true
        defer { settings.isShowMathResultsEnabled = oldMath }
        fixture.proxy.autocorrectionType = .no
        if #available(iOS 18.0, *) {
            fixture.proxy.mathExpressionCompletionType = .no
        }

        fixture.coordinator.synchronizeTextInputTraits()

        #expect(fixture.coordinator.currentAutocorrectionType == .no)
        if #available(iOS 18.0, *) {
            #expect(fixture.coordinator.shouldShowMathResults() == false)
        } else {
            #expect(fixture.coordinator.shouldShowMathResults())
        }
    }

    @Test("전송으로 입력창이 비면 스냅샷의 버퍼로 문장을 끝냄")
    func testSentTextIsRecordedWhenDocumentEmpties() {
        let fixture = makeFixture()
        fixture.host.learnableWordText = "안녕"
        fixture.service.sentenceWordsSnapshotResult = ["어"]
        fixture.proxy.beforeInput = "어 안녕"

        fixture.coordinator.captureSentTextSnapshot()
        fixture.proxy.beforeInput = nil
        fixture.proxy.afterInput = nil
        fixture.proxy.selected = nil
        fixture.coordinator.recordSentTextIfNeeded()

        #expect(fixture.service.endedSentences.count == 1)
        #expect(fixture.service.endedSentences.first?.inputBuffer == "안녕")
        #expect(fixture.service.endedSentences.first?.sentenceWords == ["어"])
    }

    @Test("기록할 입력이 없으면 스냅샷을 만들지 않아 비워져도 문장을 끝내지 않음")
    func testNoSnapshotWithoutLearnableInput() {
        let fixture = makeFixture()
        fixture.host.learnableWordText = "   "

        fixture.coordinator.captureSentTextSnapshot()
        fixture.proxy.beforeInput = nil
        fixture.coordinator.recordSentTextIfNeeded()

        #expect(fixture.service.endedSentences.isEmpty)
    }

    @Test("후보 갱신 알림은 바를 갱신하고 미리보기 하이라이트를 다시 계산")
    func testSuggestionUpdateRefreshesBar() {
        let fixture = makeFixture()
        let controller = SuggestionController(engineFactory: .stub)

        fixture.coordinator.suggestionController(controller, didUpdateCurrentWord: "안녕", suggestions: ["안녕하세요", "안녕히"])
        fixture.bar.layoutIfNeeded()

        #expect(typedSuggestionButtonViews(in: fixture.bar).count == 3)
        #expect(fixture.host.calls == ["refreshSuggestionPreviewHighlight"])
    }

    @Test("host가 해제된 뒤에는 탭·알림이 아무 것도 하지 않음")
    func testReleasedHostIsIgnored() {
        let fixture = makeFixture()
        var host: RecordingSuggestionSelectionHost? = RecordingSuggestionSelectionHost(proxy: fixture.proxy)
        let coordinator = SuggestionSelectionCoordinator(
            suggestionController: fixture.service,
            suggestionBarView: fixture.bar,
            keyboardSettingsManager: .shared,
            host: host!
        )
        host = nil
        fixture.service.currentMode = .mathExpression
        fixture.service.mathResultActionResult = .insertResult("5")

        coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 1)
        coordinator.synchronizeTextInputTraits()
        coordinator.recordSentTextIfNeeded()
        let began = coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)

        #expect(began == false)
        #expect(fixture.service.calls.isEmpty)
        #expect(fixture.service.endedSentences.isEmpty)
    }

    @Test("오버레이와 delegate가 걸린 Coordinator는 참조를 놓으면 해제됨")
    func testCoordinatorIsReleased() {
        weak var weakCoordinator: SuggestionSelectionCoordinator?
        autoreleasepool {
            let fixture = makeFixture()
            fixture.service.removableSuggestionTextResult = "오늘"
            _ = fixture.coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)
            weakCoordinator = fixture.coordinator
        }

        #expect(weakCoordinator == nil)
    }
}

// MARK: - Test Helpers

@MainActor
private final class RecordingSuggestionSelectionHost: SuggestionSelectionHost {
    var calls: [String] = []
    var currentInputBuffer = ""
    var suggestionBaseText = ""
    var learnableWordText = ""
    var isPreviewMode = false
    let overlayContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    let textDocument: CachingTextDocumentProxy

    init(proxy: CountingTextDocumentProxy) {
        textDocument = CachingTextDocumentProxy { proxy }
    }

    func insertText(_ text: String) { calls.append("insertText(\(text))") }
    func replaceText(deleteCount: Int, insert text: String) { calls.append("replaceText(\(deleteCount), \(text))") }
    func replaceTextWithSmartSpacing(deleteCount: Int, insert text: String) {
        calls.append("replaceTextWithSmartSpacing(\(deleteCount), \(text))")
    }
    func smartSpacedText(deleteCount: Int, insert text: String) -> String {
        calls.append("smartSpacedText(\(deleteCount), \(text))")
        return text
    }
    func replaceSelectedText(_ selectedText: String, with insertText: String) {
        calls.append("replaceSelectedText(\(selectedText), \(insertText))")
    }
    func suggestionDidApply() { calls.append("suggestionDidApply") }
    func refreshSuggestions() { calls.append("refreshSuggestions") }
    func refreshSuggestionPreviewHighlight() { calls.append("refreshSuggestionPreviewHighlight") }
    func undoLastEdit() { calls.append("undoLastEdit") }
    func redoLastEdit() { calls.append("redoLastEdit") }
    func interruptPendingDeleteInteractions() { calls.append("interruptPendingDeleteInteractions") }
    func toggleClipboardPanel() { calls.append("toggleClipboardPanel") }
}

@MainActor
private struct Fixture {
    let coordinator: SuggestionSelectionCoordinator
    let host: RecordingSuggestionSelectionHost
    let service: FakeSuggestionService
    let bar: SuggestionBarView
    let proxy: CountingTextDocumentProxy
}

@MainActor
private func makeFixture() -> Fixture {
    let proxy = CountingTextDocumentProxy()
    proxy.beforeInput = nil
    let host = RecordingSuggestionSelectionHost(proxy: proxy)
    let service = FakeSuggestionService()
    let bar = SuggestionBarView(keyboardHStackView: UIStackView())
    bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
    let coordinator = SuggestionSelectionCoordinator(
        suggestionController: service,
        suggestionBarView: bar,
        keyboardSettingsManager: .shared,
        host: host
    )
    service.delegate = coordinator
    bar.suggestionDelegate = coordinator
    return Fixture(coordinator: coordinator, host: host, service: service, bar: bar, proxy: proxy)
}
