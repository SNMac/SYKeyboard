//
//  KeyboardTextInteractionPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

struct DeleteInteractionGeneration: Equatable {
    fileprivate let rawValue: UInt64
}

enum DeleteInteractionDisposition: Equatable {
    case performNow
    case enqueued
}

enum PendingDeleteInteractionEvent {
    case touchDown(button: any TextInteractable)
    case pan(direction: PanDirection)
    case panStop
}

struct DeleteInteractionCancellationResult: Equatable {
    let shouldFinishPanTracking: Bool
}

enum DeleteInteractionNonDeleteMutationBoundary {

    static func cancel(
        lifecycle: inout DeleteMutationLifecycle,
        coordinator: inout DeleteInteractionCoordinator
    ) -> DeleteInteractionCancellationResult {
        lifecycle.cancel()
        return coordinator.cancel()
    }
}

/// 입력 대상이 바뀌면 진행 중인 삭제 요청을 함께 취소한다. 대상이 같으면 `nil`
enum DeleteInteractionInputChangeBoundary {

    static func cancelIfInputIdentifierChanged(
        to inputIdentifier: ObjectIdentifier?,
        lifecycle: inout DeleteMutationLifecycle,
        coordinator: inout DeleteInteractionCoordinator
    ) -> DeleteInteractionCancellationResult? {
        guard let cancellation = coordinator.cancelIfInputIdentifierChanged(to: inputIdentifier) else {
            return nil
        }
        lifecycle.cancel()
        return cancellation
    }
}

/// 확정된 삭제 mutation resolution이 VC에 요구하는 효과
struct DeleteMutationResolutionEffects: Equatable {
    /// pan 경계에서 확정된 줄바꿈처럼 복구 스택에 쌓을 글자
    let restorableCharacters: [Character]
    /// undo 기록과 피드백을 적용할지. pan 경계에서 아무것도 지우지 못했으면 적용하지 않는다
    let appliesMutationEffects: Bool
    /// coordinator를 resolve할 때 선행 no-op pan left를 버릴지
    let discardsLeadingNoOpPanLeft: Bool
}

struct DeleteInteractionCoordinator {

    // MARK: - Properties

    private(set) var currentGeneration: DeleteInteractionGeneration?
    private(set) var isWaitingForResolution = false

    private var nextGenerationRawValue: UInt64 = 0
    private var inputIdentifier: ObjectIdentifier?
    private var pendingEvents: [PendingDeleteInteractionEvent] = []
    private var isPanTrackingActive = false

    // MARK: - Internal Methods

    mutating func beginTouchDown(
        button: any TextInteractable,
        inputIdentifier: ObjectIdentifier?
    ) -> DeleteInteractionDisposition {
        guard currentGeneration != nil else {
            nextGenerationRawValue &+= 1
            currentGeneration = DeleteInteractionGeneration(rawValue: nextGenerationRawValue)
            self.inputIdentifier = inputIdentifier
            isWaitingForResolution = true
            return .performNow
        }

        pendingEvents.append(.touchDown(button: button))
        return .enqueued
    }

    mutating func enqueuePan(_ direction: PanDirection) -> DeleteInteractionDisposition {
        isPanTrackingActive = true
        guard currentGeneration != nil else { return .performNow }

        pendingEvents.append(.pan(direction: direction))
        return .enqueued
    }

    mutating func enqueuePanStop() -> DeleteInteractionDisposition {
        guard currentGeneration != nil else {
            isPanTrackingActive = false
            return .performNow
        }

        pendingEvents.append(.panStop)
        return .enqueued
    }

    mutating func beginPanBoundaryMutation(
        inputIdentifier: ObjectIdentifier?
    ) -> DeleteInteractionGeneration? {
        return beginMutation(inputIdentifier: inputIdentifier)
    }

    mutating func beginRepeatMutation(
        inputIdentifier: ObjectIdentifier?
    ) -> DeleteInteractionGeneration? {
        return beginMutation(inputIdentifier: inputIdentifier)
    }

    @discardableResult
    mutating func resolve(
        _ generation: DeleteInteractionGeneration,
        discardingLeadingNoOpPanLeft: Bool = false
    ) -> Bool {
        guard currentGeneration == generation, isWaitingForResolution else { return false }

        if discardingLeadingNoOpPanLeft {
            while case .pan(.left)? = pendingEvents.first {
                pendingEvents.removeFirst()
            }
        }
        isWaitingForResolution = false
        finishGenerationIfReadyAndEmpty()
        return true
    }

    mutating func nextReadyEvent() -> PendingDeleteInteractionEvent? {
        guard currentGeneration != nil,
              !isWaitingForResolution,
              !pendingEvents.isEmpty
        else { return nil }

        let event = pendingEvents.removeFirst()
        switch event {
        case .touchDown:
            isWaitingForResolution = true
        case .pan:
            isPanTrackingActive = true
        case .panStop:
            isPanTrackingActive = false
        }
        finishGenerationIfReadyAndEmpty()
        return event
    }

    mutating func cancel() -> DeleteInteractionCancellationResult {
        let result = DeleteInteractionCancellationResult(
            shouldFinishPanTracking: isPanTrackingActive
        )
        pendingEvents.removeAll()
        currentGeneration = nil
        inputIdentifier = nil
        isWaitingForResolution = false
        isPanTrackingActive = false
        return result
    }

    mutating func cancelIfInputIdentifierChanged(
        to inputIdentifier: ObjectIdentifier?
    ) -> DeleteInteractionCancellationResult? {
        guard currentGeneration != nil else { return nil }

        if let currentIdentifier = self.inputIdentifier,
           let inputIdentifier,
           currentIdentifier != inputIdentifier {
            return cancel()
        }
        if self.inputIdentifier == nil, let inputIdentifier {
            self.inputIdentifier = inputIdentifier
        }
        return nil
    }

    // MARK: - Private Methods

    private mutating func beginMutation(
        inputIdentifier: ObjectIdentifier?
    ) -> DeleteInteractionGeneration? {
        if let currentGeneration {
            guard !isWaitingForResolution else { return nil }
            if let currentInputIdentifier = self.inputIdentifier,
               let inputIdentifier,
               currentInputIdentifier != inputIdentifier {
                return nil
            }
            if self.inputIdentifier == nil {
                self.inputIdentifier = inputIdentifier
            }
            isWaitingForResolution = true
            return currentGeneration
        }

        nextGenerationRawValue &+= 1
        let generation = DeleteInteractionGeneration(rawValue: nextGenerationRawValue)
        currentGeneration = generation
        self.inputIdentifier = inputIdentifier
        isWaitingForResolution = true
        return generation
    }

    private mutating func finishGenerationIfReadyAndEmpty() {
        guard !isWaitingForResolution, pendingEvents.isEmpty else { return }

        currentGeneration = nil
        inputIdentifier = nil
    }
}

enum RepeatDeleteAction: Equatable {
    case deleteAwaitingTextChange(previousCompletion: RepeatDeleteCompletion?)
    case finishWithoutDeletion
}

enum RepeatDeleteMutationReliability: Equatable {
    case proxyContext
    case authoritative
}

enum RepeatDeleteConfirmationSource: Equatable {
    case textDidChange
    case checkpoint
}

enum RepeatDeleteBoundaryExpectation: Equatable {
    case newline
}

struct RepeatDeleteMutationDraft: Equatable {
    let deletedText: String
    let insertedText: String
    let reliability: RepeatDeleteMutationReliability
}

enum RepeatDeleteCompletion: Equatable {
    case mutations([RepeatDeleteMutationDraft])
    case noDeletion
}

enum RepeatDeleteCaptureResult: Equatable {
    case awaitingTextChange
    case completion(RepeatDeleteCompletion)
}

struct DeleteMutationResolution: Equatable {
    let completion: RepeatDeleteCompletion
    let origin: DeleteMutationOrigin
    let shouldPlayFeedback: Bool
}

enum DeleteMutationOrigin: Equatable {
    case touchDown
    case repeatTick
    case panBoundary
}

enum DeleteMutationCallbackOutcome: Equatable {
    case noResolution
    case resolved(DeleteMutationResolution)
    case cancelled
}

enum DeleteMutationCaptureResult: Equatable {
    case awaitingTextChange
    case completion(DeleteMutationResolution)
}

enum DeleteMutationAction: Equatable {
    case deleteAwaitingTextChange(previousResolution: DeleteMutationResolution?)
    case awaitingPreviousMutation
    case finishWithoutDeletion
}

enum DeleteMutationBoundaryAction: Equatable {
    case perform(previousResolution: DeleteMutationResolution?)
    case awaitingPreviousMutation
}

enum DeleteMutationStartResult: Equatable {
    case started
    case deferred
    case awaitingPreviousMutation
}

struct RepeatDeleteRequest {

    private struct RepeatDeleteObservation {
        let context: KeyboardTextContextSnapshot
        let selectedText: String?
    }

    // MARK: - Properties

    private var requestContext: KeyboardTextContextSnapshot?
    private var requestSelectedText: String?
    private var boundaryExpectation: RepeatDeleteBoundaryExpectation?
    private var drafts: [RepeatDeleteMutationDraft] = []
    private var callbackObservationBeforeCapture: RepeatDeleteObservation?

    var isPending: Bool {
        return requestContext != nil
    }

    var hasCapturedMutation: Bool {
        return !drafts.isEmpty
    }

    // MARK: - Internal Methods

    mutating func begin(
        context: KeyboardTextContextSnapshot,
        selectedText: String?,
        boundaryExpectation: RepeatDeleteBoundaryExpectation? = nil
    ) {
        requestContext = context
        requestSelectedText = selectedText
        self.boundaryExpectation = boundaryExpectation
        drafts.removeAll()
        callbackObservationBeforeCapture = nil
    }

    @discardableResult
    mutating func capture(
        deletedText: String,
        insertedText: String,
        reliability: RepeatDeleteMutationReliability
    ) -> RepeatDeleteCaptureResult? {
        guard requestContext != nil else { return nil }
        drafts.append(
            RepeatDeleteMutationDraft(
                deletedText: deletedText,
                insertedText: insertedText,
                reliability: reliability
            )
        )
        if let observation = callbackObservationBeforeCapture,
           let completion = complete(
                source: .textDidChange,
                currentContext: observation.context,
                currentSelectedText: observation.selectedText
            ) {
            return .completion(completion)
        }
        return .awaitingTextChange
    }

    mutating func completeAfterTextChange(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> RepeatDeleteCompletion? {
        guard let requestContext else { return nil }
        guard normalized(requestContext.afterInput) == normalized(currentContext.afterInput)
        else { return nil }

        guard !drafts.isEmpty else {
            callbackObservationBeforeCapture = RepeatDeleteObservation(
                context: currentContext,
                selectedText: currentSelectedText
            )
            return nil
        }
        return complete(
            source: .textDidChange,
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        )
    }

    mutating func completeAtCheckpoint(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> RepeatDeleteCompletion? {
        return complete(
            source: .checkpoint,
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        )
    }

    mutating func actionForNextTick(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> RepeatDeleteAction {
        guard isPending else {
            return .deleteAwaitingTextChange(previousCompletion: nil)
        }
        guard let completion = completeAtCheckpoint(
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        ) else {
            return .finishWithoutDeletion
        }
        return .deleteAwaitingTextChange(previousCompletion: completion)
    }

    mutating func completeWithoutDeletion() -> RepeatDeleteCompletion? {
        guard requestContext != nil else { return nil }
        consume()
        return .noDeletion
    }

    mutating func completeWithoutDeletionIfProven(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> RepeatDeleteCompletion? {
        guard provesNoDeletion(
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        ) else { return nil }

        consume()
        return .noDeletion
    }

    mutating func cancel() {
        consume()
    }

    // MARK: - Private Methods

    private mutating func complete(
        source: RepeatDeleteConfirmationSource,
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> RepeatDeleteCompletion? {
        guard let requestContext else { return nil }
        guard normalized(requestContext.afterInput) == normalized(currentContext.afterInput)
        else { return nil }
        let completedDrafts = confirmedDrafts(
            source: source,
            requestContext: requestContext,
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        )
        guard !completedDrafts.isEmpty else { return nil }

        consume()
        return .mutations(completedDrafts)
    }

    private func confirmedDrafts(
        source: RepeatDeleteConfirmationSource,
        requestContext: KeyboardTextContextSnapshot,
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> [RepeatDeleteMutationDraft] {
        if let requestSelectedText, !requestSelectedText.isEmpty {
            guard normalized(currentSelectedText).isEmpty,
                  normalized(requestContext.beforeInput) == normalized(currentContext.beforeInput),
                  normalized(requestContext.afterInput) == normalized(currentContext.afterInput),
                  drafts.count == 1,
                  drafts[0].reliability == .authoritative,
                  drafts[0].deletedText == requestSelectedText,
                  drafts[0].insertedText.isEmpty
            else { return [] }
            return drafts
        }

        guard normalized(currentSelectedText).isEmpty else { return [] }

        if drafts.contains(where: { $0.reliability == .authoritative }) {
            guard drafts.allSatisfy({ $0.reliability == .authoritative }),
                  let expectedBefore = expectedBeforeInput(
                    byApplying: drafts,
                    to: normalized(requestContext.beforeInput)
                  ),
                  expectedBefore != normalized(requestContext.beforeInput),
                  expectedBefore == normalized(currentContext.beforeInput)
            else { return [] }
            return drafts
        }

        let before = normalized(requestContext.beforeInput)
        let currentBefore = normalized(currentContext.beforeInput)
        guard let candidate = drafts.last else { return [] }

        if !candidate.deletedText.isEmpty,
           before.hasSuffix(candidate.deletedText),
           currentBefore == String(before.dropLast(candidate.deletedText.count)) {
            return drafts
        }

        let isSameLineContextBoundary = source == .textDidChange
            && !candidate.deletedText.isEmpty
            && currentBefore == before
        let isEmptyToPreviousLineBoundary = before.isEmpty
            && !currentBefore.isEmpty
        if isSameLineContextBoundary || isEmptyToPreviousLineBoundary {
            return [
                RepeatDeleteMutationDraft(
                    deletedText: "\n",
                    insertedText: "",
                    reliability: .authoritative
                )
            ]
        }

        guard boundaryExpectation == .newline else { return [] }

        let isSameLineCallback = source == .textDidChange && currentBefore == before
        let isEmptyToPreviousLine = before.isEmpty && !currentBefore.isEmpty
        guard isSameLineCallback || isEmptyToPreviousLine else { return [] }

        return [
            RepeatDeleteMutationDraft(
                deletedText: "\n",
                insertedText: "",
                reliability: .authoritative
            )
        ]
    }

    private func expectedBeforeInput(
        byApplying drafts: [RepeatDeleteMutationDraft],
        to beforeInput: String
    ) -> String? {
        var expectedBefore = beforeInput
        for draft in drafts {
            guard expectedBefore.hasSuffix(draft.deletedText) else { return nil }
            expectedBefore.removeLast(draft.deletedText.count)
            expectedBefore.append(draft.insertedText)
        }
        return expectedBefore
    }

    private func provesNoDeletion(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> Bool {
        guard let requestContext,
              normalized(requestSelectedText).isEmpty,
              normalized(currentSelectedText).isEmpty,
              normalized(requestContext.beforeInput).isEmpty,
              normalized(requestContext.beforeInput) == normalized(currentContext.beforeInput),
              normalized(requestContext.afterInput) == normalized(currentContext.afterInput)
        else { return false }

        return drafts.allSatisfy {
            $0.deletedText.isEmpty && $0.insertedText.isEmpty
        }
    }

    private mutating func consume() {
        requestContext = nil
        requestSelectedText = nil
        boundaryExpectation = nil
        drafts.removeAll()
        callbackObservationBeforeCapture = nil
    }

    private func normalized(_ context: String?) -> String {
        return context ?? ""
    }
}

struct DeleteMutationLifecycle {

    private enum RequestKind {
        case touchDown
        case releasedTouchDown
        case repeatTick
        case releasedRepeatTick
        case panBoundary
        case releasedPanBoundary
    }

    // MARK: - Properties

    private var request = RepeatDeleteRequest()
    private var requestKind: RequestKind?
    private var didCompleteWithoutDeletion = false

    var isPending: Bool {
        return request.isPending
    }

    var hasReleasedPanBoundaryRequest: Bool {
        return requestKind == .releasedPanBoundary
    }

    private var isReleasedRequest: Bool {
        return requestKind == .releasedTouchDown
            || requestKind == .releasedRepeatTick
            || requestKind == .releasedPanBoundary
    }

    private var isActiveRequest: Bool {
        return requestKind == .touchDown
            || requestKind == .repeatTick
            || requestKind == .panBoundary
    }

    // MARK: - Internal Methods

    @discardableResult
    mutating func beginTouchDown(
        context: KeyboardTextContextSnapshot,
        selectedText: String?
    ) -> DeleteMutationStartResult {
        guard requestKind == nil else { return .deferred }
        return begin(kind: .touchDown, context: context, selectedText: selectedText)
    }

    @discardableResult
    mutating func beginRepeat(
        context: KeyboardTextContextSnapshot,
        selectedText: String?
    ) -> DeleteMutationStartResult {
        return begin(kind: .repeatTick, context: context, selectedText: selectedText)
    }

    @discardableResult
    mutating func beginPanBoundary(
        context: KeyboardTextContextSnapshot,
        selectedText: String?
    ) -> DeleteMutationStartResult {
        guard requestKind == nil else { return .deferred }
        return begin(
            kind: .panBoundary,
            context: context,
            selectedText: selectedText,
            boundaryExpectation: .newline
        )
    }

    mutating func capture(
        deletedText: String,
        insertedText: String,
        reliability: RepeatDeleteMutationReliability
    ) -> DeleteMutationCaptureResult? {
        if isReleasedRequest {
            cancel()
            return nil
        }

        guard let captureResult = request.capture(
            deletedText: deletedText,
            insertedText: insertedText,
            reliability: reliability
        ) else { return nil }

        switch captureResult {
        case .awaitingTextChange:
            return .awaitingTextChange
        case .completion(let completion):
            guard let resolution = resolve(completion) else { return nil }
            return .completion(resolution)
        }
    }

    mutating func completeAfterTextChange(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> DeleteMutationCallbackOutcome {
        let resolution = resolve(
            request.completeAfterTextChange(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            )
        )
        if let resolution {
            return .resolved(resolution)
        }
        if isReleasedRequest {
            if let noDeletion = request.completeWithoutDeletionIfProven(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            ), let resolution = resolve(noDeletion) {
                return .resolved(resolution)
            }
            cancelCurrentRequest()
            return .cancelled
        }
        if isActiveRequest, request.hasCapturedMutation {
            cancelCurrentRequest()
            return .cancelled
        }
        return .noResolution
    }

    mutating func actionForNextRepeat(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> DeleteMutationAction {
        if didCompleteWithoutDeletion {
            return .finishWithoutDeletion
        }

        if requestKind == .touchDown
            || requestKind == .releasedTouchDown
            || requestKind == .releasedRepeatTick
            || requestKind == .panBoundary
            || requestKind == .releasedPanBoundary {
            if let completion = request.completeAtCheckpoint(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            ) {
                return .deleteAwaitingTextChange(
                    previousResolution: resolve(completion)
                )
            }
            if let noDeletion = request.completeWithoutDeletionIfProven(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            ) {
                _ = resolve(noDeletion)
                return .finishWithoutDeletion
            }
            return .awaitingPreviousMutation
        }

        switch request.actionForNextTick(
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        ) {
        case .deleteAwaitingTextChange(let previousCompletion):
            return .deleteAwaitingTextChange(
                previousResolution: resolve(previousCompletion)
            )
        case .finishWithoutDeletion:
            return .finishWithoutDeletion
        }
    }

    mutating func actionForDeletePan(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> DeleteMutationBoundaryAction {
        guard requestKind != nil else {
            didCompleteWithoutDeletion = false
            return .perform(previousResolution: nil)
        }

        if let completion = request.completeAtCheckpoint(
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        ) {
            return .perform(previousResolution: resolve(completion))
        }
        if let noDeletion = request.completeWithoutDeletionIfProven(
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        ) {
            let resolution = resolve(noDeletion)
            didCompleteWithoutDeletion = false
            return .perform(previousResolution: resolution)
        }
        return .awaitingPreviousMutation
    }

    mutating func completeAtCheckpoint(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> DeleteMutationResolution? {
        if let resolution = resolve(
            request.completeAtCheckpoint(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            )
        ) {
            return resolution
        }
        guard requestKind == .releasedPanBoundary else { return nil }
        return resolve(
            request.completeWithoutDeletionIfProven(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            )
        )
    }

    mutating func completeReleasedTouchDownAtCheckpoint(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> DeleteMutationResolution? {
        guard requestKind == .releasedTouchDown else { return nil }
        return resolve(
            request.completeAtCheckpoint(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            )
        )
    }

    mutating func finishTouchDown(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> DeleteMutationResolution? {
        guard requestKind == .touchDown else { return nil }

        let resolution = resolve(
            request.completeAtCheckpoint(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            )
        )
        if let resolution {
            return resolution
        }
        if let noDeletion = request.completeWithoutDeletionIfProven(
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        ) {
            return resolve(noDeletion)
        }
        requestKind = .releasedTouchDown
        return nil
    }

    mutating func finishPanBoundary(
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> DeleteMutationResolution? {
        guard requestKind == .panBoundary else { return nil }

        requestKind = .releasedPanBoundary
        return resolve(
            request.completeAtCheckpoint(
                currentContext: currentContext,
                currentSelectedText: currentSelectedText
            )
        )
    }

    mutating func prepareForNonDeleteEdit() {
        didCompleteWithoutDeletion = false
        guard isReleasedRequest else { return }
        cancel()
    }

    mutating func finishRepeatTracking() {
        switch requestKind {
        case .touchDown:
            requestKind = .releasedTouchDown
        case .releasedTouchDown:
            break
        case .repeatTick:
            requestKind = .releasedRepeatTick
        case .releasedRepeatTick, .panBoundary, .releasedPanBoundary, nil:
            break
        }
    }

    mutating func completeWithoutDeletion() -> RepeatDeleteCompletion? {
        let completion = request.completeWithoutDeletion()
        if completion != nil {
            requestKind = nil
            didCompleteWithoutDeletion = false
            return completion
        }
        if didCompleteWithoutDeletion {
            didCompleteWithoutDeletion = false
            return .noDeletion
        }
        return nil
    }

    mutating func cancel() {
        cancelCurrentRequest()
        didCompleteWithoutDeletion = false
    }

    // MARK: - Private Methods

    private mutating func cancelCurrentRequest() {
        request.cancel()
        requestKind = nil
    }

    private mutating func begin(
        kind: RequestKind,
        context: KeyboardTextContextSnapshot,
        selectedText: String?,
        boundaryExpectation: RepeatDeleteBoundaryExpectation? = nil
    ) -> DeleteMutationStartResult {
        guard requestKind == nil else { return .awaitingPreviousMutation }

        didCompleteWithoutDeletion = false
        request.begin(
            context: context,
            selectedText: selectedText,
            boundaryExpectation: boundaryExpectation
        )
        requestKind = kind
        return .started
    }

    private mutating func resolve(
        _ completion: RepeatDeleteCompletion?
    ) -> DeleteMutationResolution? {
        guard let completion, let requestKind else { return nil }

        self.requestKind = nil
        didCompleteWithoutDeletion = completion == .noDeletion
        let origin = origin(for: requestKind)
        return DeleteMutationResolution(
            completion: completion,
            origin: origin,
            shouldPlayFeedback: completion.isMutation
                && (origin == .repeatTick || origin == .panBoundary)
        )
    }

    private func origin(for requestKind: RequestKind) -> DeleteMutationOrigin {
        switch requestKind {
        case .touchDown, .releasedTouchDown:
            return .touchDown
        case .repeatTick, .releasedRepeatTick:
            return .repeatTick
        case .panBoundary, .releasedPanBoundary:
            return .panBoundary
        }
    }
}

private extension RepeatDeleteCompletion {
    var isMutation: Bool {
        guard case .mutations = self else { return false }
        return true
    }
}

enum KeyboardTextInteractionPolicy {

    static func shouldInsertSecondaryKey(
        insertSecondaryKeyIfAvailable: Bool,
        secondaryKey: String?
    ) -> Bool {
        return insertSecondaryKeyIfAvailable && secondaryKey != nil
    }

    /// 숫자 행을 쓸 때 길게 누르기로 입력할 shift 짝 보조 키 목록.
    ///
    /// 비shift 층은 같은 자리의 shift 문자(대문자·쌍자음), shift 층은 비shift 문자를 보조 키로 쓴다.
    /// 두 층의 문자가 같으면(두벌식 ㅁ, ㅛ 등) 보조 키를 두지 않는다
    /// - Parameter primaryKeyList: `[shift 층][행][키][문자열]` 모양의 키 배열
    static func shiftPairSecondaryKeyList(from primaryKeyList: [[[[String]]]]) -> [[[[String]]]] {
        guard primaryKeyList.count == 2 else {
            return primaryKeyList.map { $0.map { $0.map { _ in [] } } }
        }

        func pair(_ source: [[[String]]], with target: [[[String]]]) -> [[[String]]] {
            zip(source, target).map { sourceRow, targetRow in
                zip(sourceRow, targetRow).map { sourceKey, targetKey in
                    sourceKey == targetKey ? [] : targetKey
                }
            }
        }

        return [
            pair(primaryKeyList[0], with: primaryKeyList[1]),
            pair(primaryKeyList[1], with: primaryKeyList[0])
        ]
    }

    static func temporaryDeletedCharactersForSingleDelete(
        selectedText: String?,
        documentContextBeforeInput: String?
    ) -> String {
        if let selectedText, !selectedText.isEmpty {
            return String(selectedText.reversed())
        }
        if let lastBeforeCursor = documentContextBeforeInput?.last {
            return String(lastBeforeCursor)
        }
        return ""
    }

    static func shouldRequestDeletePanBoundary(
        hasText: Bool,
        documentContextBeforeInput: String?,
        selectedText: String?
    ) -> Bool {
        return hasText
            && (documentContextBeforeInput ?? "").isEmpty
            && (selectedText ?? "").isEmpty
    }

    static func mutationResolutionEffects(
        _ resolution: DeleteMutationResolution
    ) -> DeleteMutationResolutionEffects {
        let restorableCharacters = temporaryDeletedCharactersForConfirmedPanBoundary(resolution)
        return DeleteMutationResolutionEffects(
            restorableCharacters: restorableCharacters,
            appliesMutationEffects: resolution.origin != .panBoundary || !restorableCharacters.isEmpty,
            discardsLeadingNoOpPanLeft: resolution.origin == .panBoundary && resolution.completion == .noDeletion
        )
    }

    static func temporaryDeletedCharactersForConfirmedPanBoundary(
        _ resolution: DeleteMutationResolution
    ) -> [Character] {
        guard resolution.origin == .panBoundary,
              case .mutations(let drafts) = resolution.completion,
              drafts.count == 1,
              let draft = drafts.first,
              draft.deletedText == "\n",
              draft.insertedText.isEmpty,
              draft.reliability == .authoritative
        else { return [] }

        return ["\n"]
    }

    static func deletedTextForSingleBackward(
        selectedText: String?,
        documentContextBeforeInput: String?
    ) -> String {
        if let selectedText, !selectedText.isEmpty {
            return selectedText
        }
        if let lastBeforeCursor = documentContextBeforeInput?.last {
            return String(lastBeforeCursor)
        }
        return ""
    }

    static func repeatTimerInterval(repeatRate: Double) -> Double {
        return max(0.01, 0.10 - repeatRate)
    }

    static func shouldContinueRepeatInput(
        startedInputIdentifier: ObjectIdentifier?,
        currentInputIdentifier: ObjectIdentifier?
    ) -> Bool {
        guard let startedInputIdentifier else { return true }
        return startedInputIdentifier == currentInputIdentifier
    }
}
