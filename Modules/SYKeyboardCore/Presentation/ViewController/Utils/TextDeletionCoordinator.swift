//
//  TextDeletionCoordinator.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit
import Combine
import OSLog

/// `TextDeletionCoordinator`가 소유자(`BaseKeyboardViewController`)에게 요구하는 것.
/// 삭제 파이프라인의 프록시 쓰기는 전부 VC의 `open`/`public` 메서드를 거치므로 대부분 같은 이름으로 witness가 된다.
/// `performDeleteTextInteraction(for:)`는 기본 인자가 있는 `performTextInteraction(for:)`를, `recordEditForUndo`는 private
/// `recordUndoRedoChange`를, `refreshSuggestions`는 private `updateSuggestions`를 감싼 이름이다
@MainActor
protocol TextDeletionHost: AnyObject {
    /// VC의 프록시 창구. Coordinator는 이 값을 저장하지 않고 호출마다 읽는다. 캐시 범위가 VC 콜백에 묶여 있기 때문이다
    var textDocument: CachingTextDocumentProxy { get }
    /// VC의 private `inputBuffer`. 단일 삭제의 대치 복구 판정에 쓴다
    var currentInputBuffer: String { get }
    /// 반복 타이머가 창 밖이면 멈추기 위한 판정
    var isViewInWindow: Bool { get }

    func textInteractionWillPerform(button: TextInteractable)
    func textInteractionDidPerform(button: TextInteractable)
    func deleteBackward()
    func repeatDeleteBackward()
    func deleteText()
    func replaceText(deleteCount: Int, insert text: String)
    func deleteButtonPanDeleteText(hasPendingRestoreText: Bool) -> (character: Character, shouldRestore: Bool)?
    func deleteButtonPanRestoreText(_ character: Character)
    func deleteButtonPanDidStop()
    func performRepeatTextInteraction(for button: TextInteractable)
    /// VC의 `performTextInteraction(for:)`. 한글 VC의 첫 반복 삭제가 조합 상태를 보존한 채 일반 삭제 경로를 타게 한다
    func performDeleteTextInteraction(for button: TextInteractable)
    /// VC의 `recordUndoRedoChange(deletedText:insertedText:)`. 확정된 draft를 undo에 기록할 때 부른다
    func recordEditForUndo(deletedText: String, insertedText: String)
    func refreshSuggestions()
}

/// 삭제 touchDown·반복 틱·pan 삭제/복구·줄 경계 추론·보류 큐 drain·반복 입력 타이머·삭제 드래그 인디케이터를 맡는다.
/// 삭제 파이프라인 상태(`DeleteMutationLifecycle`, `DeleteInteractionCoordinator`)와 pan 모델·복구 버퍼·타이머를 소유하고,
/// 실제 프록시 쓰기와 하위 VC 훅은 host에 요청한다.
/// host는 `weak`다. `DispatchQueue.main.asyncAfter`와 타이머 sink가 이 객체를 VC보다 오래 살릴 수 있으므로
/// host가 필요한 진입점은 `guard let host`로 시작하고, 상태만 바꾸는 메서드는 host 없이 동작한다
@MainActor
final class TextDeletionCoordinator {

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "TextDeletionCoordinator")

    /// 현재 반복 입력 동작 중인지 확인하는 플래그. VC가 `isRepeatingInput`으로 노출한다
    private(set) var isRepeatingInput: Bool = false
    /// 삭제 버튼 팬 제스처가 다음에 지울 커서 앞 글자. VC가 `deleteButtonPanPreviousCharacter`로 노출한다
    ///
    /// 입력창이 늦게 보낸 낡은 문맥을 읽지 않도록 `documentContextBeforeInput` 대신 드래그 시작 때 읽은 모델을 따른다
    var panPreviousCharacter: Character? {
        return deletePanTextModel?.lastCharacter
    }

    /// 반복 입력용 타이머
    private var timer: AnyCancellable?
    /// 진단용 반복 입력 tick 수. 구간으로만 기록한다
    private var repeatInputTickCount: Int = 0
    /// touchDown과 반복 삭제 요청을 실제 문맥 변경 확인 후 성공 또는 무효로 한 번만 완료합니다.
    private var deleteMutationLifecycle = DeleteMutationLifecycle()
    /// 삭제 touchDown, pan, pan stop을 generation 단위 FIFO로 조정합니다.
    private var deleteInteractionCoordinator = DeleteInteractionCoordinator()
    /// 보류 삭제 drain 중 동기 callback 재진입을 막습니다.
    private var isDrainingPendingDeleteInteractions = false
    /// 현재 host text input의 식별자입니다.
    private var currentTextInputIdentifier: ObjectIdentifier?
    /// 삭제 버튼 팬 제스처로 인해 임시로 삭제된 내용을 저장하는 변수
    private var tempDeletedCharacters: [Character] = []
    /// 삭제 버튼 팬 제스처 동안 커서 앞 문맥을 대신하는 모델(드래그 시작 때 한 번 읽음)
    private var deletePanTextModel: DeletePanTextModel?
    /// 삭제 버튼 팬 제스처가 마지막으로 문서를 편집한 시각
    private var lastDeletePanEditTime: CFTimeInterval = 0
    /// 삭제 버튼 팬 제스처가 줄 경계를 넘을 때의 대기·막힘 상태
    private var deletePanBoundaryState = DeletePanBoundaryState()
    /// 다음 `deleteText()`가 undo에 기록할 삭제 문자열(삭제 버튼 팬 제스처가 모델에서 정한 값)
    private var deletePanDeletedTextOverride: String?

    private let deleteDragIndicatorView: CursorDragIndicatorView
    private let suggestionController: SuggestionService
    private let keyboardSettingsManager: UserDefaultsManager
    private weak var host: TextDeletionHost?

    // MARK: - Initializer

    init(
        deleteDragIndicatorView: CursorDragIndicatorView,
        suggestionController: SuggestionService,
        keyboardSettingsManager: UserDefaultsManager,
        host: TextDeletionHost
    ) {
        self.deleteDragIndicatorView = deleteDragIndicatorView
        self.suggestionController = suggestionController
        self.keyboardSettingsManager = keyboardSettingsManager
        self.host = host
    }

    deinit {
        logger.debug("TextDeletionCoordinator deinit")
    }

    // MARK: - Text Change Callbacks

    /// `textWillChange`/`textDidChange`에서 VC가 부른다. 입력창이 바뀌었으면 진행·보류 삭제를 모두 취소한다
    func synchronizeInputIdentifier(_ inputIdentifier: ObjectIdentifier?) {
        if let cancellation = DeleteInteractionInputChangeBoundary.cancelIfInputIdentifierChanged(
            to: inputIdentifier,
            lifecycle: &deleteMutationLifecycle,
            coordinator: &deleteInteractionCoordinator
        ) {
            finishCancelledDeletePanIfNeeded(cancellation)
        }
        if let inputIdentifier {
            currentTextInputIdentifier = inputIdentifier
        }
    }

    /// `textDidChange`에서 VC가 부른다. 앞·뒤 문맥은 VC가 커서 햅틱 판정에 쓴 스냅샷을 그대로 받아 읽기 횟수를 유지한다
    func completeAfterTextChange(currentContext: KeyboardTextContextSnapshot) {
        guard let host else { return }
        let deleteMutationOutcome = deleteMutationLifecycle.completeAfterTextChange(
            currentContext: currentContext,
            currentSelectedText: host.textDocument.selectedText
        )
        processDeleteMutationCallbackOutcome(deleteMutationOutcome)
        resumePendingDeletePanBoundaryIfNeeded()
    }

    /// `viewWillDisappear`에서 VC가 부른다
    func resetInputIdentifier() {
        currentTextInputIdentifier = nil
    }

    // MARK: - Touch Down

    /// 삭제 버튼 touchDown. 반복 중이 아니면 released 요청을 체크포인트로 확정하고 새 요청을 시작한다
    func performTouchDown(for button: TextInteractable) {
        guard let host else { return }
        if !isRepeatingInput {
            let previousResolution = deleteMutationLifecycle
                .completeReleasedTouchDownAtCheckpoint(
                    currentContext: host.textDocument.contextSnapshot,
                    currentSelectedText: host.textDocument.selectedText
                )
            processDeleteMutationResolution(previousResolution)

            let disposition = deleteInteractionCoordinator.beginTouchDown(
                button: button,
                inputIdentifier: currentTextInputIdentifier
            )
            if disposition == .enqueued {
                return
            }
            guard beginDeleteTouchDownRequest() == .started else {
                cancelPendingInteractions()
                return
            }
        }
        performDeleteTextInteractionWithSemanticHooks(for: button) {
            performDeleteButtonTextInteraction()
        }
    }

    /// 삭제 버튼 release. 확정 가능하면 즉시 resolve, 아니면 released로 전환해 `textDidChange`를 기다린다
    func finishTouchDown() {
        guard let host else { return }
        let resolution = deleteMutationLifecycle.finishTouchDown(
            currentContext: host.textDocument.contextSnapshot,
            currentSelectedText: host.textDocument.selectedText
        )
        processDeleteMutationResolution(resolution)
    }

    /// 삭제가 아닌 입력, undo/redo, 클립보드 패널 열기처럼 진행·보류 삭제를 모두 버려야 할 때
    func cancelPendingInteractions() {
        finishCancelledDeletePanIfNeeded(
            DeleteInteractionNonDeleteMutationBoundary.cancel(
                lifecycle: &deleteMutationLifecycle,
                coordinator: &deleteInteractionCoordinator
            )
        )
    }

    /// 래퍼가 수행한 편집을 삭제 파이프라인에 캡처한다. VC의 `recordUndoRedoChange`가 먼저 부른다.
    /// - Returns: 파이프라인이 처리했으면 `true`(기다리거나 확정했음). `false`면 VC가 undo에 바로 기록한다
    func captureMutation(
        deletedText: String,
        insertedText: String,
        reliability: RepeatDeleteMutationReliability
    ) -> Bool {
        let captureResult = deleteMutationLifecycle.capture(
            deletedText: deletedText,
            insertedText: insertedText,
            reliability: reliability
        )
        switch captureResult {
        case .awaitingTextChange:
            return true
        case .completion(let resolution):
            processDeleteMutationResolution(resolution)
            return true
        case nil:
            return false
        }
    }

    /// pan 삭제가 모델에서 정한 지울 글자. VC의 `deleteText()`가 받아 가며 한 번 읽으면 지워진다
    func takePanDeletedTextOverride() -> String? {
        defer { deletePanDeletedTextOverride = nil }
        return deletePanDeletedTextOverride
    }

    /// `textInteractionWillPerform`에서 VC가 부른다. 삭제 이외의 입력이 끼어들면 복구 버퍼가 사라진다
    func clearPanRestoreState() {
        tempDeletedCharacters.removeAll()
        resetDeletePanTextModel()
    }

    // MARK: - Repeat Input

    /// `repeatTextInteractionWillPerform`에서 VC가 부른다
    func beginRepeatInput() {
        // 방어 코드
        cancelTimer()
        isRepeatingInput = true
    }

    /// `repeatTextInteractionDidPerform`에서 VC가 부른다. 삭제 버튼이면 마지막 틱을 확정 시도한다
    func endRepeatInput(isDeleteButton: Bool) {
        if isDeleteButton {
            completeRepeatDeleteAtCurrentContext()
        }
        stopRepeatInputTracking(preservingTouchDown: isDeleteButton)
        tempDeletedCharacters.removeAll()
        resetDeletePanTextModel()
    }

    /// 반복 타이머 틱의 삭제 버튼 처리
    func performRepeatTick(for button: TextInteractable) {
        performDeleteTextInteractionWithSemanticHooks(for: button) {
            performRepeatDeleteTextInteraction()
        }
    }

    /// 한글 조합 상태를 보존하는 첫 반복 삭제. `view.window` 확인은 VC에 남아 있다
    func performInitialRepeatDelete(for button: TextInteractable) {
        guard let host else { return }
        let action = deleteMutationLifecycle.actionForNextRepeat(
            currentContext: host.textDocument.contextSnapshot,
            currentSelectedText: host.textDocument.selectedText
        )
        switch action {
        case .deleteAwaitingTextChange(let previousResolution):
            processDeleteMutationResolution(previousResolution)
            guard beginRepeatDeleteRequest() == .started else { return }
            host.performDeleteTextInteraction(for: button)
        case .awaitingPreviousMutation:
            return
        case .finishWithoutDeletion:
            finishRepeatDeleteWithoutDeletion()
        }
    }

    func startRepeatInputTimer(for button: TextInteractable) {
        let repeatTimerInterval = KeyboardTextInteractionPolicy.repeatTimerInterval(
            repeatRate: keyboardSettingsManager.repeatRate
        )
        repeatInputTickCount = 0
        KeyboardDiagnostics.log(
            "repeatInput start button=\(String(describing: type(of: button))) interval=\(repeatTimerInterval)"
        )
        let startedInputIdentifier = currentTextInputIdentifier
        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self, weak button] _ in
                guard let self else { return }
                if !KeyboardTextInteractionPolicy.shouldContinueRepeatInput(
                    startedInputIdentifier: startedInputIdentifier,
                    currentInputIdentifier: self.currentTextInputIdentifier
                ) {
                    self.stopRepeatInputTracking()
                    return
                }
                guard let host = self.host, host.isViewInWindow else {
                    self.stopRepeatInputTracking()
                    return
                }
                guard let button else {
                    self.stopRepeatInputTracking()
                    return
                }

                host.performRepeatTextInteraction(for: button)
            }
        logger.debug("반복 타이머 생성")
    }

    func stopRepeatInputTracking(preservingTouchDown: Bool = false) {
        KeyboardDiagnostics.log(
            "repeatInput stop ticks=\(KeyboardDiagnostics.bucket(repeatInputTickCount))"
            + " preservingTouchDown=\(preservingTouchDown)"
        )
        cancelTimer()
        if preservingTouchDown {
            deleteMutationLifecycle.finishRepeatTracking()
        } else {
            cancelPendingInteractions()
        }
        isRepeatingInput = false
    }

    // MARK: - Delete Pan

    /// `deleteButtonPanning`에서 VC가 부른다
    func handlePan(to direction: PanDirection) {
        showDeleteDragOverlays()
        guard deleteInteractionCoordinator.enqueuePan(direction) == .performNow else {
            // 경계 요청을 보내기 전이면 방향을 바꾼 사용자를 기다리게 하지 않는다
            if deletePanBoundaryState.shouldCancelPendingBeforeSend(on: .pan(direction: direction)) {
                cancelPendingDeletePanBoundary()
            }
            return
        }
        performDeleteButtonPanIfLifecycleReady(to: direction)
    }

    /// `deleteButtonPanStopped`에서 VC가 부른다
    func handlePanStop() {
        hideDeleteDragOverlays()
        guard deleteInteractionCoordinator.enqueuePanStop() == .performNow else {
            // 경계 요청을 보내기 전이면 손을 뗀 뒤에 보내지 않고 바로 끝낸다
            if deletePanBoundaryState.shouldCancelPendingBeforeSend(on: .panStop) {
                cancelPendingDeletePanBoundary()
                return
            }
            guard let host else { return }
            let generation = deleteInteractionCoordinator.currentGeneration
            let resolution = deleteMutationLifecycle.finishPanBoundary(
                currentContext: host.textDocument.contextSnapshot,
                currentSelectedText: host.textDocument.selectedText
            )
            processDeleteMutationResolution(resolution)
            if let generation,
               resolution == nil,
               deleteMutationLifecycle.hasReleasedPanBoundaryRequest {
                scheduleReleasedPanBoundaryCheckpoint(for: generation)
            }
            return
        }
        finishDeleteButtonPanTracking()
    }
}

// MARK: - Private Methods

private extension TextDeletionCoordinator {
    func performDeleteTextInteractionWithSemanticHooks(
        for button: TextInteractable,
        body: () -> Void
    ) {
        guard let host else { return }
        let wasDraining = isDrainingPendingDeleteInteractions
        isDrainingPendingDeleteInteractions = true
        host.textInteractionWillPerform(button: button)
        defer {
            host.textInteractionDidPerform(button: button)
            isDrainingPendingDeleteInteractions = wasDraining
            if !wasDraining {
                drainPendingDeleteInteractionsIfPossible()
            }
        }
        body()
    }

    func performRepeatDeleteTextInteraction() {
        guard let host else { return }
        repeatInputTickCount += 1
        let context = host.textDocument.contextSnapshot
        let selectedText = host.textDocument.selectedText
        let action = deleteMutationLifecycle.actionForNextRepeat(
            currentContext: context,
            currentSelectedText: selectedText
        )
        switch action {
        case .deleteAwaitingTextChange(let previousResolution):
            // 처리할 이전 결과가 없으면 그 사이 프록시가 바뀌지 않으므로 방금 읽은 문맥을 다시 쓴다.
            // 프록시 읽기는 UIKit 내부 레이스로 크래시할 수 있어 틱마다 읽는 횟수를 줄인다
            let startState = previousResolution == nil ? (context, selectedText) : nil
            processDeleteMutationResolution(previousResolution)
            guard beginRepeatDeleteRequest(reusing: startState) == .started else { return }
            host.repeatDeleteBackward()
        case .awaitingPreviousMutation:
            return
        case .finishWithoutDeletion:
            finishRepeatDeleteWithoutDeletion()
        }
    }

    func beginDeleteTouchDownRequest() -> DeleteMutationStartResult {
        // 호출자가 모두 `guard let host` 뒤라 도달하지 않는다. `.started`만 아니면 되므로 `.deferred`를 돌려준다
        guard let host else { return .deferred }
        return deleteMutationLifecycle.beginTouchDown(
            context: host.textDocument.contextSnapshot,
            selectedText: host.textDocument.selectedText
        )
    }

    /// - Parameter startState: 같은 틱에서 이미 읽은 문맥. `nil`이면 프록시에서 새로 읽는다
    func beginRepeatDeleteRequest(
        reusing startState: (KeyboardTextContextSnapshot, String?)? = nil
    ) -> DeleteMutationStartResult {
        // 호출자가 모두 `guard let host` 뒤라 도달하지 않는다. `.started`만 아니면 되므로 `.deferred`를 돌려준다
        guard let host else { return .deferred }
        guard deleteInteractionCoordinator.beginRepeatMutation(
            inputIdentifier: currentTextInputIdentifier
        ) != nil else {
            return .awaitingPreviousMutation
        }

        let (context, selectedText) = startState
            ?? (host.textDocument.contextSnapshot, host.textDocument.selectedText)
        let result = deleteMutationLifecycle.beginRepeat(
            context: context,
            selectedText: selectedText
        )
        guard result == .started else {
            cancelPendingInteractions()
            return result
        }
        return .started
    }

    func performDeleteButtonTextInteraction() {
        guard let host else { return }
        if let restore = suggestionController.attemptRestoreReplacement(
            inputBuffer: host.currentInputBuffer,
            documentContextBeforeInput: host.textDocument.documentContextBeforeInput,
            selectedText: host.textDocument.selectedText
        ) {
            host.replaceText(deleteCount: restore.deleteCount, insert: restore.insertText)
            return
        }

        let deletedCharacters = KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
            selectedText: host.textDocument.selectedText,
            documentContextBeforeInput: host.textDocument.documentContextBeforeInput
        )
        tempDeletedCharacters.append(contentsOf: deletedCharacters)
        host.deleteBackward()
    }

    func processDeleteMutationResolution(_ resolution: DeleteMutationResolution?) {
        guard let resolution, let host else { return }

        let effects = KeyboardTextInteractionPolicy.mutationResolutionEffects(resolution)
        tempDeletedCharacters.append(contentsOf: effects.restorableCharacters)
        deletePanBoundaryState.didResolve(resolution)
        if resolution.origin == .panBoundary, !effects.restorableCharacters.isEmpty {
            // 줄바꿈을 지워 새로 보이는 이전 줄로 모델을 다시 채운다
            deletePanTextModel = DeletePanTextModel(beforeInput: host.textDocument.documentContextBeforeInput)
        }

        if effects.appliesMutationEffects,
           case .mutations(let drafts) = resolution.completion {
            for draft in drafts {
                host.recordEditForUndo(
                    deletedText: draft.deletedText,
                    insertedText: draft.insertedText
                )
            }
        }
        if effects.appliesMutationEffects && resolution.shouldPlayFeedback {
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playDeleteSound()
        }
        guard !effects.settlesBeforeResumingPan else {
            resumeDeletePanAfterSettling()
            return
        }
        resolvePendingDeleteInteractionsIfNeeded(
            discardingLeadingNoOpPanLeft: effects.discardsLeadingNoOpPanLeft
        )
        drainPendingDeleteInteractionsIfPossible()
    }

    /// 줄바꿈 삭제 뒤 입력창이 늦게 보내는 callback을 먼저 받은 다음 보류된 pan을 이어서 재생합니다.
    func resumeDeletePanAfterSettling() {
        guard let generation = deleteInteractionCoordinator.currentGeneration else { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + KeyboardTextInteractionPolicy.deletePanBoundaryQuietInterval
        ) { [weak self] in
            guard let self,
                  self.deleteInteractionCoordinator.currentGeneration == generation,
                  self.deleteInteractionCoordinator.isWaitingForResolution,
                  !self.deleteMutationLifecycle.isPending
            else { return }

            self.resolvePendingDeleteInteractionsIfNeeded(discardingLeadingNoOpPanLeft: false)
            self.drainPendingDeleteInteractionsIfPossible()
        }
    }

    func processDeleteMutationCallbackOutcome(_ outcome: DeleteMutationCallbackOutcome) {
        switch outcome {
        case .noResolution:
            break
        case .resolved(let resolution):
            processDeleteMutationResolution(resolution)
        case .cancelled:
            cancelPendingInteractions()
        }
    }

    func resolvePendingDeleteInteractionsIfNeeded(
        discardingLeadingNoOpPanLeft: Bool
    ) {
        guard let generation = deleteInteractionCoordinator.currentGeneration else { return }
        _ = deleteInteractionCoordinator.resolve(
            generation,
            discardingLeadingNoOpPanLeft: discardingLeadingNoOpPanLeft
        )
    }

    @discardableResult
    func completeRepeatDeleteAtCurrentContext() -> Bool {
        guard let host else { return false }
        let resolution = deleteMutationLifecycle.completeAtCheckpoint(
            currentContext: host.textDocument.contextSnapshot,
            currentSelectedText: host.textDocument.selectedText
        )
        guard resolution != nil else { return false }

        processDeleteMutationResolution(resolution)
        return true
    }

    func cancelTimer() {
        timer?.cancel()
        timer = nil
        logger.debug("반복 타이머 초기화")
    }

    func finishRepeatDeleteWithoutDeletion() {
        KeyboardDiagnostics.log("repeatDelete exhausted")
        guard deleteMutationLifecycle.completeWithoutDeletion() == .noDeletion else { return }

        stopRepeatInputTracking()
    }

    func showDeleteDragOverlays() {
        deleteDragIndicatorView.isHidden = false
    }

    func hideDeleteDragOverlays() {
        deleteDragIndicatorView.isHidden = true
    }

    func drainPendingDeleteInteractionsIfPossible() {
        guard !isDrainingPendingDeleteInteractions, let host else { return }

        isDrainingPendingDeleteInteractions = true
        defer { isDrainingPendingDeleteInteractions = false }

        while let event = deleteInteractionCoordinator.nextReadyEvent() {
            switch event {
            case .touchDown(let button):
                guard beginDeleteTouchDownRequest() == .started else {
                    cancelPendingInteractions()
                    return
                }
                performDeleteTextInteractionWithSemanticHooks(for: button) {
                    performDeleteButtonTextInteraction()
                }
                let resolution = deleteMutationLifecycle.finishTouchDown(
                    currentContext: host.textDocument.contextSnapshot,
                    currentSelectedText: host.textDocument.selectedText
                )
                processDeleteMutationResolution(resolution)
                if deleteMutationLifecycle.isPending {
                    return
                }
            case .pan(let direction):
                performDeleteButtonPanIfLifecycleReady(to: direction)
                if deleteMutationLifecycle.isPending {
                    return
                }
            case .panStop:
                finishDeleteButtonPanTracking()
            }
        }
    }

    func finishCancelledDeletePanIfNeeded(_ cancellation: DeleteInteractionCancellationResult) {
        guard cancellation.shouldFinishPanTracking else { return }

        hideDeleteDragOverlays()
        tempDeletedCharacters.removeAll()
        resetDeletePanTextModel()
        host?.deleteButtonPanDidStop()
        logger.debug("취소된 삭제 pan 임시 상태 초기화")
    }

    func performDeleteButtonPanInteraction(to direction: PanDirection) {
        switch direction {
        case .left:
            performDeleteButtonPanDeleteIfPossible()
        case .right:
            performDeleteButtonPanRestoreIfPossible()
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }

    func performDeleteButtonPanIfLifecycleReady(to direction: PanDirection) {
        guard let host else { return }
        let action = deleteMutationLifecycle.actionForDeletePan(
            currentContext: host.textDocument.contextSnapshot,
            currentSelectedText: host.textDocument.selectedText
        )
        switch action {
        case .perform(let previousResolution):
            processDeleteMutationResolution(previousResolution)
            performDeleteButtonPanInteraction(to: direction)
        case .awaitingPreviousMutation:
            return
        }
    }

    /// 드래그의 첫 삭제·복구 전에 커서 앞 문맥을 한 번 읽어 모델을 만듭니다.
    func prepareDeletePanTextModelIfNeeded() {
        guard deletePanTextModel == nil, let host else { return }
        deletePanTextModel = DeletePanTextModel(beforeInput: host.textDocument.documentContextBeforeInput)
    }

    func resetDeletePanTextModel() {
        deletePanTextModel = nil
        deletePanBoundaryState.reset()
    }

    func scheduleReleasedPanBoundaryCheckpoint(
        for generation: DeleteInteractionGeneration
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let host = self.host,
                  self.deleteInteractionCoordinator.currentGeneration == generation,
                  self.deleteInteractionCoordinator.isWaitingForResolution,
                  self.deleteMutationLifecycle.hasReleasedPanBoundaryRequest
            else { return }

            let resolution = self.deleteMutationLifecycle.completeAtCheckpoint(
                currentContext: host.textDocument.contextSnapshot,
                currentSelectedText: host.textDocument.selectedText
            )
            guard let resolution else {
                self.cancelPendingInteractions()
                return
            }
            self.processDeleteMutationResolution(resolution)
        }
    }

    func finishDeleteButtonPanTracking() {
        tempDeletedCharacters.removeAll()
        resetDeletePanTextModel()
        host?.deleteButtonPanDidStop()
        logger.debug("임시 삭제 내용 저장 변수 초기화")
    }

    func performDeleteButtonPanDeleteIfPossible() {
        guard let host else { return }
        prepareDeletePanTextModelIfNeeded()
        let selectedText = host.textDocument.selectedText
        // 되살릴 수 없는 첨부·토큰 앞에서는 지우지 않고 멈춘다
        guard !KeyboardTextInteractionPolicy.shouldStopDeletePan(
            previousCharacter: panPreviousCharacter,
            selectedText: selectedText
        ) else { return }
        deletePanDeletedTextOverride = panPreviousCharacter.map(String.init)
        let deleteResult = host.deleteButtonPanDeleteText(
            hasPendingRestoreText: !tempDeletedCharacters.isEmpty
        )
        deletePanDeletedTextOverride = nil
        if let deleteResult {
            lastDeletePanEditTime = CACurrentMediaTime()
            if KeyboardTextInteractionPolicy.shouldTrackDeletePanStep(selectedText: selectedText) {
                deletePanTextModel?.removeLast()
                if deleteResult.shouldRestore {
                    tempDeletedCharacters.append(deleteResult.character)
                }
            }
            host.refreshSuggestions()
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playDeleteSound()
            return
        }

        guard !deletePanBoundaryState.isBlocked,
              KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: host.textDocument.hasText,
                hasDeletedInCurrentPan: !tempDeletedCharacters.isEmpty,
                documentContextBeforeInput: deletePanTextModel?.remainingText,
                selectedText: host.textDocument.selectedText
              ) else { return }
        guard let generation = deleteInteractionCoordinator.beginPanBoundaryMutation(
            inputIdentifier: currentTextInputIdentifier
        ) else { return }
        deletePanBoundaryState.beginPending(generation: generation)

        // 입력창이 직전 편집을 반영할 시간을 준 뒤 앞 문맥을 본다
        let delay = KeyboardTextInteractionPolicy.deletePanBoundaryDelay(
            elapsedSinceLastEdit: CACurrentMediaTime() - lastDeletePanEditTime
        )
        guard delay > 0 else {
            evaluatePendingDeletePanBoundary(for: generation)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.evaluatePendingDeletePanBoundary(for: generation)
        }
    }

    /// 모델이 바닥난 뒤 입력창 앞 문맥을 보고 경계를 묻거나, 기다리거나, 모델을 다시 채웁니다.
    ///
    /// 경계 요청(`deleteBackward()`)을 보내기 전 단계라서 이 동안의 방향 전환·팬 종료는 바로 취소할 수 있습니다.
    func evaluatePendingDeletePanBoundary(for generation: DeleteInteractionGeneration) {
        guard let host,
              deletePanBoundaryState.isPending(generation: generation),
              deleteInteractionCoordinator.currentGeneration == generation,
              deleteInteractionCoordinator.isWaitingForResolution,
              !deleteMutationLifecycle.hasPanBoundaryRequest
        else { return }

        switch KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
            sourceText: deletePanTextModel?.sourceText ?? "",
            documentContextBeforeInput: host.textDocument.documentContextBeforeInput
        ) {
        case .requestBoundary:
            sendDeletePanBoundaryRequest(for: generation)
        case .awaitSync:
            waitForDeletePanBoundaryContextSync(for: generation)
        case .refill:
            // 모델이 잘려 있었으므로 보이는 앞 문맥으로 다시 채우고, 경계를 묻지 않은 채 이어서 지운다
            deletePanTextModel = DeletePanTextModel(beforeInput: host.textDocument.documentContextBeforeInput)
            finishPendingDeletePanBoundaryWithoutRequest(discardingLeadingNoOpPanLeft: false)
            performDeleteButtonPanDeleteIfPossible()
            drainPendingDeleteInteractionsIfPossible()
        }
    }

    func sendDeletePanBoundaryRequest(for generation: DeleteInteractionGeneration) {
        guard let host else { return }
        let timeoutID = deletePanBoundaryState.didSendRequest()
        guard deleteMutationLifecycle.beginPanBoundary(
            context: host.textDocument.contextSnapshot,
            selectedText: host.textDocument.selectedText
        ) == .started else {
            deleteMutationLifecycle.cancel()
            finishCancelledDeletePanIfNeeded(deleteInteractionCoordinator.cancel())
            return
        }

        lastDeletePanEditTime = CACurrentMediaTime()
        host.deleteText()
        scheduleDeletePanBoundaryTimeout(for: generation, timeoutID: timeoutID)
    }

    /// 입력창 문맥이 따라오기를 기다리고, 끝내 따라오지 않으면 경계를 넘지 않고 끝냅니다.
    func waitForDeletePanBoundaryContextSync(for generation: DeleteInteractionGeneration) {
        guard let waitID = deletePanBoundaryState.beginSyncWait() else { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + KeyboardTextInteractionPolicy.deletePanBoundaryTimeout
        ) { [weak self] in
            guard let self,
                  self.deletePanBoundaryState.isCurrentSyncWait(waitID),
                  self.deletePanBoundaryState.isPending(generation: generation),
                  self.deleteInteractionCoordinator.currentGeneration == generation,
                  self.deleteInteractionCoordinator.isWaitingForResolution,
                  !self.deleteMutationLifecycle.hasPanBoundaryRequest
            else { return }

            self.cancelPendingDeletePanBoundary()
        }
    }

    /// 경계 요청을 보내기 전 단계의 대기를 취소하고, 이번 드래그에서는 더 이상 경계를 넘지 않습니다.
    func cancelPendingDeletePanBoundary() {
        deletePanBoundaryState.cancelPending()
        resolvePendingDeleteInteractionsIfNeeded(discardingLeadingNoOpPanLeft: true)
        drainPendingDeleteInteractionsIfPossible()
    }

    func finishPendingDeletePanBoundaryWithoutRequest(discardingLeadingNoOpPanLeft: Bool) {
        deletePanBoundaryState.finishPendingWithoutRequest()
        resolvePendingDeleteInteractionsIfNeeded(
            discardingLeadingNoOpPanLeft: discardingLeadingNoOpPanLeft
        )
    }

    func resumePendingDeletePanBoundaryIfNeeded() {
        // 마지막 드래그 편집 뒤 조용한 시간이 지나기 전에는 예약된 판정에 맡긴다.
        // 그 사이 callback은 드래그 전 문맥을 담고 있을 수 있어 모델을 잘못 다시 채울 수 있다
        guard let generation = deletePanBoundaryState.pendingGeneration,
              KeyboardTextInteractionPolicy.deletePanBoundaryDelay(
                elapsedSinceLastEdit: CACurrentMediaTime() - lastDeletePanEditTime
              ) == 0
        else { return }
        evaluatePendingDeletePanBoundary(for: generation)
    }

    /// callback 없이 경계 요청이 끝나지 않으면 일정 시간 뒤 확정해 드래그가 멈추지 않게 합니다.
    func scheduleDeletePanBoundaryTimeout(
        for generation: DeleteInteractionGeneration,
        timeoutID: Int
    ) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + KeyboardTextInteractionPolicy.deletePanBoundaryTimeout
        ) { [weak self] in
            guard let self,
                  let host = self.host,
                  self.deleteInteractionCoordinator.currentGeneration == generation,
                  self.deleteInteractionCoordinator.isWaitingForResolution,
                  self.deleteMutationLifecycle.hasPanBoundaryRequest,
                  // 입력창 확인 없이 확정하므로 이번 드래그에서는 더 이상 경계를 넘지 않는다
                  self.deletePanBoundaryState.requestDidTimeOut(timeoutID)
            else { return }

            self.processDeleteMutationResolution(
                self.deleteMutationLifecycle.completePanBoundaryAfterTimeout(
                    currentContext: host.textDocument.contextSnapshot,
                    currentSelectedText: host.textDocument.selectedText
                )
            )
        }
    }

    func performDeleteButtonPanRestoreIfPossible() {
        guard let host else { return }
        guard let lastDeleted = tempDeletedCharacters.popLast() else { return }

        prepareDeletePanTextModelIfNeeded()
        host.deleteButtonPanRestoreText(lastDeleted)
        deletePanTextModel?.append(lastDeleted)
        lastDeletePanEditTime = CACurrentMediaTime()
        host.refreshSuggestions()
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playDeleteSound()
    }
}
