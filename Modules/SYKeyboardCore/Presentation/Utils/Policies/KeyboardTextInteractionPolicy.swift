//
//  KeyboardTextInteractionPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

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

struct RepeatDeleteRequest {

    private struct RepeatDeleteObservation {
        let context: KeyboardTextContextSnapshot
        let selectedText: String?
    }

    // MARK: - Properties

    private var requestContext: KeyboardTextContextSnapshot?
    private var requestSelectedText: String?
    private var drafts: [RepeatDeleteMutationDraft] = []
    private var callbackObservationBeforeCapture: RepeatDeleteObservation?

    var isPending: Bool {
        return requestContext != nil
    }

    // MARK: - Internal Methods

    mutating func begin(
        context: KeyboardTextContextSnapshot,
        selectedText: String?
    ) {
        requestContext = context
        requestSelectedText = selectedText
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
        isRepeatingInput: Bool,
        currentContext: KeyboardTextContextSnapshot,
        currentSelectedText: String?
    ) -> RepeatDeleteCompletion? {
        guard isRepeatingInput, let requestContext else { return nil }
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
           currentBefore == String(before.dropLast(candidate.deletedText.count)) {
            return drafts
        }

        let isSameLineContextBoundary = source == .textDidChange
            && !candidate.deletedText.isEmpty
            && currentBefore == before
        let isEmptyToPreviousLineBoundary = before.isEmpty
            && !currentBefore.isEmpty
        guard isSameLineContextBoundary || isEmptyToPreviousLineBoundary else { return [] }

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

    private mutating func consume() {
        requestContext = nil
        requestSelectedText = nil
        drafts.removeAll()
        callbackObservationBeforeCapture = nil
    }

    private func normalized(_ context: String?) -> String {
        return context ?? ""
    }
}

enum KeyboardTextInteractionPolicy {

    static func shouldInsertSecondaryKey(
        insertSecondaryKeyIfAvailable: Bool,
        secondaryKey: String?
    ) -> Bool {
        return insertSecondaryKeyIfAvailable && secondaryKey != nil
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
}
