//
//  UndoRedoCoordinator.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit
import OSLog

/// `UndoRedoCoordinator`가 소유자(`BaseKeyboardViewController`)에게 요구하는 것.
/// `shouldDeferUndoRedoCommit`·`undoRedoEditDidApply`는 VC의 `open` 멤버라 같은 이름으로 witness가 되고,
/// `refresh…`/`interrupt…`는 VC의 private 메서드를 감싼 이름이다. 같은 파일의 Host 채택 extension이 한 줄로 전달한다
@MainActor
protocol UndoRedoHost: AnyObject {
    /// VC의 프록시 창구. Coordinator는 이 값을 저장하지 않고 호출마다 읽는다. 캐시 범위가 VC 콜백에 묶여 있기 때문이다
    var textDocument: CachingTextDocumentProxy { get }
    /// `BaseKeyboardViewController.isPreview`. 앱 미리보기에서는 undo/redo를 적용하지 않는다
    var isPreviewMode: Bool { get }
    /// 조합 중인 텍스트가 있을 때 undo 단위 확정을 미루기 위한 hook
    var shouldDeferUndoRedoCommit: Bool { get }

    func undoRedoEditDidApply()
    func refreshReturnButtonEnabled()
    func refreshSuggestions()
    func refreshClipboardControl()
    func interruptPendingDeleteInteractions()
}

/// undo/redo 기록·그룹 확정·무효화·적용과 후보 바의 undo/redo 컨트롤 갱신을 맡는다.
/// `KeyboardUndoRedoSession`을 소유하고, 삭제 확정 파이프라인과의 접점(capture 뒤 기록, 적용 전 삭제 취소)은 VC를 거친다.
/// host는 `weak`다. 디바운스 확정 클로저가 이 객체를 VC보다 오래 살릴 수 있으므로 host가 필요한 진입점은 `guard let host`로 시작한다
@MainActor
final class UndoRedoCoordinator {

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "UndoRedoCoordinator")

    /// 키보드 세션 동안만 유지되는 undo/redo 상태 관리자
    private var undoRedoSession = KeyboardUndoRedoSession()

    private let suggestionBarView: SuggestionBarView
    private let suggestionController: SuggestionService
    private let keyboardSettingsManager: UserDefaultsManager
    private weak var host: UndoRedoHost?

    /// undo/redo 기능 사용 가능 여부. 자동완성 설정과 독립이다
    private var isUndoRedoFeatureAvailable: Bool {
        return keyboardSettingsManager.isUndoRedoEnabled
    }

    // MARK: - Initializer

    init(
        suggestionBarView: SuggestionBarView,
        suggestionController: SuggestionService,
        keyboardSettingsManager: UserDefaultsManager,
        host: UndoRedoHost
    ) {
        self.suggestionBarView = suggestionBarView
        self.suggestionController = suggestionController
        self.keyboardSettingsManager = keyboardSettingsManager
        self.host = host
    }

    deinit {
        logger.debug("UndoRedoCoordinator deinit")
    }

    // MARK: - Text Change Callbacks

    /// `textWillChange`에서 VC가 부른다. 식별자는 VC가 `textInputIdentifier(for:)`로 계산해 넘긴다
    func prepareForTextWillChange(inputIdentifier: ObjectIdentifier?) {
        guard let host else { return }
        undoRedoSession.prepareForTextWillChange(
            inputIdentifier: inputIdentifier,
            context: host.textDocument.contextSnapshot
        )
    }

    /// `textDidChange`에서 VC가 부른다. 입력창이 바뀌었으면 이력과 대치 이력을 비운다
    func invalidateHistoryIfNeededAfterTextChange(inputIdentifier: ObjectIdentifier?) {
        guard let host else { return }
        if undoRedoSession.shouldInvalidateAfterTextChange(
            inputIdentifier: inputIdentifier,
            currentContext: host.textDocument.contextSnapshot
        ) {
            invalidateHistoryForTextContextChange()
            suggestionController.clearReplacementHistory()
        }
    }

    /// `viewWillDisappear`에서 VC가 부른다. 세션 한정 기능이라 이력을 모두 지운다
    func removeAllHistory() {
        undoRedoSession.removeAll()
        refreshControls()
    }

    // MARK: - Recording

    /// 삭제 확정 파이프라인이 capture하지 않은 편집을 기록한다. VC의 `recordUndoRedoChange`가 부른다
    func record(deletedText: String, insertedText: String) {
        guard let host,
              isUndoRedoFeatureAvailable,
              !undoRedoSession.isApplyingEdit else { return }
        undoRedoSession.record(
            deletedText: deletedText,
            insertedText: insertedText,
            targetContext: host.textDocument.contextSnapshot,
            shouldDeferCommit: { [weak self] in
                self?.host?.shouldDeferUndoRedoCommit == true
            },
            debouncedCommitDidFinish: { [weak self] in
                self?.refreshControls()
            }
        )
        refreshControls()
    }

    /// 스페이스/리턴처럼 사용자가 명시적인 편집 경계를 만든 경우 pending undo 단위를 확정한다
    func commitPendingGroup() {
        guard let host else { return }
        undoRedoSession.commitPendingGroup(shouldDeferCommit: host.shouldDeferUndoRedoCommit)
        refreshControls()
    }

    /// 삭제 시작처럼 조합 중이어도 이전 편집 단위를 끊어야 하는 경우 pending undo 단위를 확정한다
    func commitPendingGroupIgnoringDeferral() {
        guard isUndoRedoFeatureAvailable else { return }

        undoRedoSession.commitPendingGroupIgnoringDeferral()
        refreshControls()
    }

    /// 조합 확정 지연 요청이 있었고 현재 확정 가능한 상태라면 pending undo 단위를 stack에 반영한다
    func commitDeferredGroupIfNeeded() {
        guard let host,
              undoRedoSession.commitDeferredGroupIfNeeded(
                shouldDeferCommit: host.shouldDeferUndoRedoCommit
              ) else { return }
        refreshControls()
    }

    // MARK: - Applying

    func undo() {
        guard let host, isUndoRedoFeatureAvailable else { return }

        host.interruptPendingDeleteInteractions()
        undoRedoSession.cancelDebounceTimer()
        guard undoRedoSession.canApplyUndo(from: host.textDocument.contextSnapshot) else {
            refreshControls()
            return
        }
        guard let edit = undoRedoSession.undo() else {
            refreshControls()
            return
        }
        guard applyEdit(edit, host: host) else {
            invalidateHistoryForTextContextChange()
            return
        }
        undoRedoSession.updateLastRedoTargetContext(host.textDocument.contextSnapshot)
        refreshControls()
        FeedbackManager.shared.playHaptic()
    }

    func redo() {
        guard let host, isUndoRedoFeatureAvailable else { return }

        host.interruptPendingDeleteInteractions()
        undoRedoSession.cancelDebounceTimer()
        guard undoRedoSession.canApplyRedo(from: host.textDocument.contextSnapshot) else {
            refreshControls()
            return
        }
        guard let edit = undoRedoSession.redo() else {
            refreshControls()
            return
        }
        guard applyEdit(edit, host: host) else {
            invalidateHistoryForTextContextChange()
            return
        }
        undoRedoSession.updateLastUndoTargetContext(host.textDocument.contextSnapshot)
        refreshControls()
        FeedbackManager.shared.playHaptic()
    }

    // MARK: - Controls

    /// 후보 바의 undo/redo 버튼 표시·활성 상태를 갱신하고 끝에 클립보드 버튼도 갱신한다
    func refreshControls() {
        guard let host else { return }
        let shouldShowUndoRedo = KeyboardPresentationStatePolicy.shouldShowUndoRedoControls(
            isSuggestionBarHidden: suggestionBarView.isHidden,
            isUndoRedoFeatureAvailable: isUndoRedoFeatureAvailable
        )
        // 기록이 없으면 결과가 문맥과 무관하게 false다.
        // 키보드가 사라질 때처럼 문서 상태가 교체되는 순간 프록시를 읽으면 크래시하므로 읽지 않는다
        let hasUndoRedoHistory = undoRedoSession.canUndo || undoRedoSession.canRedo
        let currentContext = hasUndoRedoHistory
            ? host.textDocument.contextSnapshot
            : KeyboardTextContextSnapshot(beforeInput: nil, afterInput: nil)
        suggestionBarView.updateUndoRedoControls(
            isVisible: shouldShowUndoRedo,
            canUndo: undoRedoSession.canApplyUndo(from: currentContext),
            canRedo: undoRedoSession.canApplyRedo(from: currentContext)
        )
        host.refreshClipboardControl()
    }
}

// MARK: - Private Methods

private extension UndoRedoCoordinator {
    func applyEdit(_ edit: KeyboardUndoRedoEdit, host: UndoRedoHost) -> Bool {
        guard !host.isPreviewMode else { return false }

        return undoRedoSession.performApplyingEdit {
            guard restoreTextPositionIfPossible(to: edit.targetContext, host: host) else { return false }

            for _ in 0..<edit.deleteCount {
                host.textDocument.deleteBackward()
            }
            if !edit.insertText.isEmpty {
                host.textDocument.insertText(edit.insertText)
            }

            host.undoRedoEditDidApply()
            host.refreshReturnButtonEnabled()
            host.refreshSuggestions()
            return true
        }
    }

    func restoreTextPositionIfPossible(to targetContext: KeyboardTextContextSnapshot?, host: UndoRedoHost) -> Bool {
        guard let targetContext else { return true }

        guard let offset = KeyboardTextContextNavigator.cursorOffset(
            from: host.textDocument.contextSnapshot,
            to: targetContext
        ) else {
            return false
        }

        if offset != 0 {
            host.textDocument.adjustTextPosition(byCharacterOffset: offset)
        }
        return true
    }

    func invalidateHistoryForTextContextChange() {
        guard !undoRedoSession.isApplyingEdit else { return }
        undoRedoSession.removeAll()
        refreshControls()
    }
}
