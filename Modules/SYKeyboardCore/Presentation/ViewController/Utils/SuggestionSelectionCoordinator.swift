//
//  SuggestionSelectionCoordinator.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit
import OSLog
import SYKeyboardAssets

/// `SuggestionSelectionCoordinator`가 소유자(`BaseKeyboardViewController`)에게 요구하는 것.
/// `refresh…`/`…LastEdit`/`interrupt…`/`…SmartSpacing`/`smartSpacedText`는 VC의 private 메서드를 감싼 이름이다.
/// `currentInputBuffer`는 VC의 private `inputBuffer`를 읽기 전용으로 노출한다
@MainActor
protocol SuggestionSelectionHost: AnyObject {
    /// VC의 프록시 창구. Coordinator는 이 값을 저장하지 않고 호출마다 읽는다. 캐시 범위가 VC 콜백에 묶여 있기 때문이다
    var textDocument: CachingTextDocumentProxy { get }
    var currentInputBuffer: String { get }
    /// VC의 `generalSuggestionBaseText`(일반 후보의 기준 텍스트)
    var suggestionBaseText: String { get }
    /// VC의 `learnableInputBuffer`(앞 글자에 붙은 조각을 뺀 버퍼)
    var learnableWordText: String { get }
    /// `BaseKeyboardViewController.isPreview`
    var isPreviewMode: Bool { get }
    /// 삭제 확인 오버레이를 올릴 뷰. 키보드 전체를 덮는다
    var overlayContainerView: UIView { get }

    func insertText(_ text: String)
    func replaceText(deleteCount: Int, insert text: String)
    func replaceTextWithSmartSpacing(deleteCount: Int, insert text: String)
    func smartSpacedText(deleteCount: Int, insert text: String) -> String
    func replaceSelectedText(_ selectedText: String, with insertText: String)
    func suggestionDidApply()
    func refreshSuggestions()
    func refreshSuggestionPreviewHighlight()
    func undoLastEdit()
    func redoLastEdit()
    func interruptPendingDeleteInteractions()
    func toggleClipboardPanel()
}

/// 전송 판정과 기록에 쓰는 `textWillChange` 시점의 입력 상태
private struct SentTextSnapshot {
    let inputBuffer: String
    let sentenceWords: [String]
    let documentIdentifier: UUID?
}

/// 후보 바의 탭·길게 누르기·기능 버튼, `SuggestionController`의 후보 갱신 알림, 입력 trait 동기화, 전송 기록, 후보 삭제 확인 오버레이를 맡는다.
/// host는 `weak`다. 바와 컨트롤러의 delegate가 이 객체를 참조하므로 모든 진입점이 `guard let host`로 시작한다
@MainActor
final class SuggestionSelectionCoordinator {

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "SuggestionSelectionCoordinator")

    /// host 입력 변경 callback에서 마지막으로 확인한 자동 수정 설정. VC가 바 숨김 판정에 읽는다
    private(set) var currentAutocorrectionType: UITextAutocorrectionType?
    /// host 입력 변경 callback에서 마지막으로 확인한 수식 자동완성 허용 상태
    private var isMathExpressionCompletionAllowed = true
    private var pendingSentTextSnapshot: SentTextSnapshot?
    /// 자동완성 후보 삭제 확인 오버레이. 처음 길게 누를 때 만든다
    private var suggestionRemovalConfirmView: DeleteConfirmOverlayView?
    /// 삭제 확인을 기다리는 자동완성 단어
    private var pendingSuggestionRemovalWord: String?

    private let suggestionController: SuggestionService
    private let suggestionBarView: SuggestionBarView
    private let keyboardSettingsManager: UserDefaultsManager
    private weak var host: SuggestionSelectionHost?

    // MARK: - Initializer

    init(
        suggestionController: SuggestionService,
        suggestionBarView: SuggestionBarView,
        keyboardSettingsManager: UserDefaultsManager,
        host: SuggestionSelectionHost
    ) {
        self.suggestionController = suggestionController
        self.suggestionBarView = suggestionBarView
        self.keyboardSettingsManager = keyboardSettingsManager
        self.host = host
    }

    deinit {
        logger.debug("SuggestionSelectionCoordinator deinit")
    }

    // MARK: - Internal Methods

    /// `textWillChange`/`textDidChange`의 `withReadCaching` 안에서 VC가 부른다
    func synchronizeTextInputTraits() {
        guard let host else { return }
        currentAutocorrectionType = host.textDocument.autocorrectionType

        if #available(iOS 18.0, *) {
            isMathExpressionCompletionAllowed =
                host.textDocument.mathExpressionCompletionType != .no
        } else {
            isMathExpressionCompletionAllowed = true
        }
    }

    func shouldShowMathResults() -> Bool {
        return KeyboardPresentationStatePolicy.shouldShowMathResults(
            isSettingEnabled: keyboardSettingsManager.isShowMathResultsEnabled,
            isHostCompletionAllowed: isMathExpressionCompletionAllowed
        )
    }

    /// `textWillChange`에서 VC가 부른다. 기록하지 않은 입력이 있을 때만 스냅샷을 만든다
    func captureSentTextSnapshot() {
        guard let host else { return }
        let buffer = host.learnableWordText
        guard buffer.contains(where: { !$0.isWhitespace }) else {
            pendingSentTextSnapshot = nil
            return
        }
        pendingSentTextSnapshot = SentTextSnapshot(
            inputBuffer: buffer,
            sentenceWords: suggestionController.sentenceWordsSnapshot(),
            documentIdentifier: host.textDocument.documentIdentifier
        )
    }

    /// `textDidChange`에서 VC가 부른다. 입력창이 전송으로 비었으면 스냅샷의 마지막 단어까지 기록하고 문장을 끝낸다
    func recordSentTextIfNeeded() {
        guard let host, let snapshot = pendingSentTextSnapshot else { return }
        pendingSentTextSnapshot = nil
        guard KeyboardSentTextDetectionPolicy.isSentAfterTextChange(
            documentIdentifierBeforeChange: snapshot.documentIdentifier,
            documentIdentifierAfterChange: host.textDocument.documentIdentifier,
            beforeInput: host.textDocument.documentContextBeforeInput,
            afterInput: host.textDocument.documentContextAfterInput,
            selectedText: host.textDocument.selectedText,
            returnKeyType: host.textDocument.returnKeyType
        ) else { return }

        suggestionController.endSentence(
            inputBuffer: snapshot.inputBuffer,
            restoringSentenceWords: snapshot.sentenceWords
        )
    }

    /// `viewWillDisappear`에서 VC가 부른다
    func hideSuggestionRemovalConfirmation() {
        pendingSuggestionRemovalWord = nil
        suggestionRemovalConfirmView?.isHidden = true
    }

    /// `viewWillDisappear`에서 VC가 부른다. 키보드가 내려가면 전송 판정 대상이 없다
    func discardSentTextSnapshot() {
        pendingSentTextSnapshot = nil
    }

    /// 수식 결과 action을 적용한다. 스페이스 입력 경로에서도 VC가 부른다
    @discardableResult
    func applyMathResultSuggestionAction(_ action: MathResultSuggestionAction) -> Bool {
        guard let host else { return false }
        switch action {
        case .confirmOriginal:
            suggestionController.clearSuggestions()
        case .insertResult(let text):
            host.insertText(text)
        case .replaceExpression(let deleteCount, let insertText):
            host.replaceText(deleteCount: deleteCount, insert: insertText)
        case .replaceSelection(let text):
            guard let selectedText = host.textDocument.selectedText,
                  !selectedText.isEmpty else { return false }
            host.replaceSelectedText(selectedText, with: text)
        }
        return true
    }
}

// MARK: - Private Methods

private extension SuggestionSelectionCoordinator {
    func handleSelectedTextSuggestion(at index: Int, host: SuggestionSelectionHost) -> Bool {
        guard let selectedText = host.textDocument.selectedText,
              !selectedText.isEmpty else { return false }

        if index == 0 {
            // 현재 선택된 단어 확정, 후보 비우기
            suggestionController.clearSuggestions()
            return true
        }

        let suggestionIndex = index - 1
        guard suggestionIndex >= 0,
              let result = suggestionController.selectSuggestion(
                at: suggestionIndex,
                baseText: selectedText
              ) else { return true }

        let insertText = host.smartSpacedText(
            deleteCount: 0,
            insert: result.insertText
        )

        host.replaceSelectedText(selectedText, with: insertText)

        host.suggestionDidApply()
        host.refreshSuggestions()
        return true
    }

    func handleMathResultSuggestion(at index: Int, host: SuggestionSelectionHost) -> Bool {
        guard suggestionController.currentMode == .mathExpression else { return false }

        guard let action = suggestionController.mathResultAction(
            at: index,
            selectedText: host.textDocument.selectedText
        ) else { return true }
        guard applyMathResultSuggestionAction(action) else { return true }

        if case .confirmOriginal = action {
            return true
        } else {
            host.suggestionDidApply()
            host.refreshSuggestions()
        }
        return true
    }

    func handleNGramSuggestion(at index: Int, host: SuggestionSelectionHost) -> Bool {
        guard suggestionController.currentMode == .nGram else { return false }
        guard let word = suggestionController.nGramSuggestionText(at: index) else { return true }

        if KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
            baseText: host.suggestionBaseText
        ) {
            host.insertText(" ")
        }

        host.insertText(word)

        host.suggestionDidApply()

        suggestionController.updateSuggestionsAfterNGramSelection(
            baseText: host.suggestionBaseText,
            textReplacementBaseText: host.currentInputBuffer
        )
        return true
    }

    func handleCurrentWordConfirmationIfNeeded(at index: Int, host: SuggestionSelectionHost) -> Bool {
        guard index == 0 else { return false }

        let currentWord = KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(
            inputBuffer: host.learnableWordText
        )
        if !currentWord.isEmpty {
            suggestionController.learnWord(currentWord)
            suggestionController.recordWord(currentWord)
        }
        suggestionController.clearSuggestions()
        return true
    }

    func handleInputBufferSuggestion(at index: Int, host: SuggestionSelectionHost) {
        let suggestionIndex = index - 1
        guard let result = suggestionController.selectSuggestion(
            at: suggestionIndex,
            baseText: host.suggestionBaseText,
            textReplacementBaseText: host.currentInputBuffer
        ) else { return }

        host.replaceTextWithSmartSpacing(
            deleteCount: result.deleteCount,
            insert: result.insertText
        )

        suggestionController.recordWord(result.insertText)

        host.suggestionDidApply()
        host.refreshSuggestions()
    }

    // MARK: Suggestion Removal

    func showSuggestionRemovalConfirmation(for word: String, host: SuggestionSelectionHost) {
        let overlay = suggestionRemovalConfirmView ?? makeSuggestionRemovalConfirmView(in: host.overlayContainerView)
        pendingSuggestionRemovalWord = word
        overlay.update(
            title: String(localized: "'\(word)'을(를) 자동완성에서 삭제할까요?", bundle: SYKBDAssets.bundle),
            message: String(localized: "다시 입력하면 다시 학습됩니다.", bundle: SYKBDAssets.bundle)
        )
        // 나중에 붙은 오버레이보다 위에 보이도록 매번 앞으로 가져온다
        host.overlayContainerView.bringSubviewToFront(overlay)
        overlay.isHidden = false
        FeedbackManager.shared.playHaptic()
    }

    func confirmSuggestionRemoval() {
        guard let word = pendingSuggestionRemovalWord else { return }
        hideSuggestionRemovalConfirmation()
        suggestionController.removeSuggestionWord(word)
    }

    /// 키보드 전체를 덮어 확인하는 동안 키 입력을 막는다
    func makeSuggestionRemovalConfirmView(in container: UIView) -> DeleteConfirmOverlayView {
        let overlay = DeleteConfirmOverlayView()
        overlay.isHidden = true
        overlay.onCancel = { [weak self] in self?.hideSuggestionRemovalConfirmation() }
        overlay.onConfirm = { [weak self] in self?.confirmSuggestionRemoval() }
        container.addSubview(overlay)

        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: container.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        suggestionRemovalConfirmView = overlay
        return overlay
    }
}

// MARK: - SuggestionControllerDelegate

extension SuggestionSelectionCoordinator: SuggestionControllerDelegate {
    func suggestionController(_ controller: SuggestionController, didUpdateCurrentWord currentWord: String?, suggestions: [String]) {
        guard let host else { return }
        if controller.currentMode == .mathExpression {
            suggestionBarView.updateSuggestions(
                currentWord: nil,
                suggestions: suggestions
            )
        } else {
            // 길게 눌러 삭제할 수 있는 칸만 medium으로 표시한다. 삭제가 막힌 미리보기에서는 표시도 하지 않는다
            let removableIndices = host.isPreviewMode ? IndexSet() : controller.removableBarIndices
            suggestionBarView.updateSuggestions(
                currentWord: currentWord,
                suggestions: suggestions,
                removableIndices: removableIndices
            )
        }

        host.refreshSuggestionPreviewHighlight()
    }
}

// MARK: - SuggestionBarDelegate

extension SuggestionSelectionCoordinator: SuggestionBarDelegate {
    func suggestionBar(_ bar: SuggestionBarView, didSelectSuggestionAt index: Int) {
        guard let host else { return }
        host.interruptPendingDeleteInteractions()
        if handleMathResultSuggestion(at: index, host: host) { return }
        if handleSelectedTextSuggestion(at: index, host: host) { return }
        if handleNGramSuggestion(at: index, host: host) { return }
        if handleCurrentWordConfirmationIfNeeded(at: index, host: host) { return }
        handleInputBufferSuggestion(at: index, host: host)
    }

    func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool {
        guard let host, !host.isPreviewMode,
              let word = suggestionController.removableSuggestionText(atBarIndex: index) else { return false }
        showSuggestionRemovalConfirmation(for: word, host: host)
        return true
    }

    func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {
        host?.undoLastEdit()
    }

    func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {
        host?.redoLastEdit()
    }

    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView) {
        // 미리보기는 실제 키보드와 같은 모습을 보여주는 것이 목적이라 버튼을 비활성으로 만들지 않고,
        // 패널만 열지 않는다. undo/redo가 미리보기에서 회색인 것은 세션이 비어 canUndo가 false이기 때문이다
        guard let host, !host.isPreviewMode else { return }
        host.toggleClipboardPanel()
    }
}
