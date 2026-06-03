//
//  KeyboardUndoRedoManager.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/21/26.
//

import Combine
import Foundation

struct KeyboardUndoRedoEdit: Equatable {
    let deleteCount: Int
    let insertText: String
    let targetContext: KeyboardTextContextSnapshot?

    init(
        deleteCount: Int,
        insertText: String,
        targetContext: KeyboardTextContextSnapshot? = nil
    ) {
        self.deleteCount = deleteCount
        self.insertText = insertText
        self.targetContext = targetContext
    }
}

struct KeyboardTextContextSnapshot: Equatable {
    let beforeInput: String?
    let afterInput: String?
}

struct KeyboardTextContextNavigator {

    static let maximumCursorRestoreDistance = 256

    // MARK: - Internal Methods

    static func cursorOffset(
        from source: KeyboardTextContextSnapshot,
        to target: KeyboardTextContextSnapshot
    ) -> Int? {
        if context(source, matches: target) { return 0 }

        let maxLeftDistance = min(
            source.beforeInput?.count ?? 0,
            maximumCursorRestoreDistance
        )
        let maxRightDistance = min(
            source.afterInput?.count ?? 0,
            maximumCursorRestoreDistance
        )
        let maxDistance = max(maxLeftDistance, maxRightDistance)

        guard maxDistance > 0 else { return nil }

        for distance in 1...maxDistance {
            if distance <= maxLeftDistance,
               context(source, movingBy: -distance, matches: target) {
                return -distance
            }

            if distance <= maxRightDistance,
               context(source, movingBy: distance, matches: target) {
                return distance
            }
        }

        return nil
    }

    // MARK: - Private Methods

    private static func context(
        _ source: KeyboardTextContextSnapshot,
        matches target: KeyboardTextContextSnapshot
    ) -> Bool {
        return beforeContext(source.beforeInput, matches: target.beforeInput)
        && afterContext(source.afterInput, matches: target.afterInput)
    }

    private static func context(
        _ source: KeyboardTextContextSnapshot,
        movingBy offset: Int,
        matches target: KeyboardTextContextSnapshot
    ) -> Bool {
        guard offset != 0 else { return context(source, matches: target) }

        if offset < 0 {
            guard let beforeInput = source.beforeInput,
                  let splitIndex = beforeInput.index(
                    beforeInput.endIndex,
                    offsetBy: offset,
                    limitedBy: beforeInput.startIndex
                  ) else {
                return false
            }

            return beforeContext(beforeInput[..<splitIndex], matches: target.beforeInput)
            && afterContext(
                prefix: beforeInput[splitIndex...],
                suffix: source.afterInput,
                matches: target.afterInput
            )
        } else {
            guard let afterInput = source.afterInput,
                  let splitIndex = afterInput.index(
                    afterInput.startIndex,
                    offsetBy: offset,
                    limitedBy: afterInput.endIndex
                  ) else {
                return false
            }

            return beforeContext(
                prefix: source.beforeInput,
                suffix: afterInput[..<splitIndex],
                matches: target.beforeInput
            )
            && afterContext(afterInput[splitIndex...], matches: target.afterInput)
        }
    }

    private static func beforeContext(_ source: String?, matches target: String?) -> Bool {
        guard let target else { return true }
        guard !target.isEmpty else { return source?.isEmpty != false }
        return source?.hasSuffix(target) == true
    }

    private static func afterContext(_ source: String?, matches target: String?) -> Bool {
        guard let target else { return true }
        guard !target.isEmpty else { return source?.isEmpty != false }
        return source?.hasPrefix(target) == true
    }

    private static func beforeContext(_ source: Substring, matches target: String?) -> Bool {
        guard let target else { return true }
        guard !target.isEmpty else { return source.isEmpty }
        return source.hasSuffix(target)
    }

    private static func beforeContext(
        prefix: String?,
        suffix: Substring,
        matches target: String?
    ) -> Bool {
        guard let target else { return true }
        guard !target.isEmpty else {
            return prefix?.isEmpty != false && suffix.isEmpty
        }

        let suffixCount = suffix.count
        if target.count <= suffixCount {
            return suffix.hasSuffix(target)
        }

        guard let prefix else { return false }

        let targetSuffixStart = target.index(target.endIndex, offsetBy: -suffixCount)
        let targetPrefix = target[..<targetSuffixStart]
        let targetSuffix = target[targetSuffixStart...]

        return suffix.elementsEqual(targetSuffix)
        && prefix.hasSuffix(String(targetPrefix))
    }

    private static func afterContext(_ source: Substring, matches target: String?) -> Bool {
        guard let target else { return true }
        guard !target.isEmpty else { return source.isEmpty }
        return source.hasPrefix(target)
    }

    private static func afterContext(
        prefix: Substring,
        suffix: String?,
        matches target: String?
    ) -> Bool {
        guard let target else { return true }
        guard !target.isEmpty else {
            return prefix.isEmpty && suffix?.isEmpty != false
        }

        let prefixCount = prefix.count
        if target.count <= prefixCount {
            return prefix.hasPrefix(target)
        }

        guard let suffix else { return false }

        let targetPrefixEnd = target.index(target.startIndex, offsetBy: prefixCount)
        let targetPrefix = target[..<targetPrefixEnd]
        let targetSuffix = target[targetPrefixEnd...]

        return prefix.elementsEqual(targetPrefix)
        && suffix.hasPrefix(String(targetSuffix))
    }
}

struct KeyboardUndoRedoManager {

    // MARK: - Properties

    private let maxHistoryCount: Int
    private var undoStack: [KeyboardTextMutation] = []
    private var redoStack: [KeyboardTextMutation] = []
    private var pendingMutation: KeyboardTextMutation?

    var canUndo: Bool {
        return pendingMutation != nil || !undoStack.isEmpty
    }

    var canRedo: Bool {
        return !redoStack.isEmpty
    }

    func canApplyUndo(from currentContext: KeyboardTextContextSnapshot) -> Bool {
        guard let edit = nextUndoEdit else { return false }
        return canApply(edit, from: currentContext)
    }

    func canApplyRedo(from currentContext: KeyboardTextContextSnapshot) -> Bool {
        guard let edit = nextRedoEdit else { return false }
        return canApply(edit, from: currentContext)
    }

    // MARK: - Initializer

    init(maxHistoryCount: Int = 100) {
        self.maxHistoryCount = maxHistoryCount
    }

    // MARK: - Internal Methods

    mutating func record(
        deletedText: String,
        insertedText: String,
        targetContext: KeyboardTextContextSnapshot?
    ) {
        guard !deletedText.isEmpty || !insertedText.isEmpty else { return }

        let mutation = KeyboardTextMutation(
            deletedText: deletedText,
            insertedText: insertedText,
            undoTargetContext: targetContext,
            redoTargetContext: nil
        )

        guard !mutation.isNoop else { return }

        redoStack.removeAll()

        if let currentPendingMutation = pendingMutation {
            if currentPendingMutation.shouldStartNewGroup(before: mutation) {
                commitPendingGroup()
                pendingMutation = mutation
            } else {
                pendingMutation?.merge(with: mutation)
                if pendingMutation?.isNoop == true {
                    pendingMutation = nil
                }
            }
        } else {
            pendingMutation = mutation
        }
    }

    mutating func undo() -> KeyboardUndoRedoEdit? {
        commitPendingGroup()
        guard let mutation = undoStack.popLast() else { return nil }
        redoStack.append(mutation)
        return mutation.undoEdit
    }

    mutating func redo() -> KeyboardUndoRedoEdit? {
        commitPendingGroup()
        guard let mutation = redoStack.popLast() else { return nil }
        undoStack.append(mutation)
        return mutation.redoEdit
    }

    mutating func updateLastUndoTargetContext(_ context: KeyboardTextContextSnapshot?) {
        guard !undoStack.isEmpty else { return }
        undoStack[undoStack.count - 1].undoTargetContext = context
    }

    mutating func updateLastRedoTargetContext(_ context: KeyboardTextContextSnapshot?) {
        guard !redoStack.isEmpty else { return }
        redoStack[redoStack.count - 1].redoTargetContext = context
    }

    mutating func commitPendingGroup() {
        guard let mutation = pendingMutation else { return }
        undoStack.append(mutation)
        pendingMutation = nil
        trimUndoStackIfNeeded()
    }

    mutating func removeAll() {
        pendingMutation = nil
        undoStack.removeAll()
        redoStack.removeAll()
    }

    // MARK: - Private Methods

    private mutating func trimUndoStackIfNeeded() {
        guard undoStack.count > maxHistoryCount else { return }
        undoStack.removeFirst(undoStack.count - maxHistoryCount)
    }

    private var nextUndoEdit: KeyboardUndoRedoEdit? {
        if let pendingMutation {
            return pendingMutation.undoEdit
        }
        return undoStack.last?.undoEdit
    }

    private var nextRedoEdit: KeyboardUndoRedoEdit? {
        return redoStack.last?.redoEdit
    }

    private func canApply(
        _ edit: KeyboardUndoRedoEdit,
        from currentContext: KeyboardTextContextSnapshot
    ) -> Bool {
        guard let targetContext = edit.targetContext else { return true }
        return KeyboardTextContextNavigator.cursorOffset(
            from: currentContext,
            to: targetContext
        ) != nil
    }
}

final class KeyboardUndoRedoSession {

    // MARK: - Properties

    private var manager = KeyboardUndoRedoManager()
    private var debounceTimer: AnyCancellable?
    private let debounceInterval: TimeInterval
    private var needsDeferredCommit: Bool = false
    private var pendingTextChangeContext: KeyboardTextContextSnapshot?
    private var pendingTextChangeInputIdentifier: ObjectIdentifier?
    private var currentTextInputIdentifier: ObjectIdentifier?

    private(set) var isApplyingEdit: Bool = false

    var canUndo: Bool {
        return manager.canUndo
    }

    var canRedo: Bool {
        return manager.canRedo
    }

    func canApplyUndo(from currentContext: KeyboardTextContextSnapshot) -> Bool {
        return manager.canApplyUndo(from: currentContext)
    }

    func canApplyRedo(from currentContext: KeyboardTextContextSnapshot) -> Bool {
        return manager.canApplyRedo(from: currentContext)
    }

    // MARK: - Initializer

    init(debounceInterval: TimeInterval = 0.8) {
        self.debounceInterval = debounceInterval
    }

    // MARK: - Internal Methods

    func record(
        deletedText: String,
        insertedText: String,
        targetContext: KeyboardTextContextSnapshot,
        shouldDeferCommit: @escaping () -> Bool,
        debouncedCommitDidFinish: @escaping () -> Void
    ) {
        manager.record(
            deletedText: deletedText,
            insertedText: insertedText,
            targetContext: targetContext
        )
        scheduleDebounceCommit(
            shouldDeferCommit: shouldDeferCommit,
            debouncedCommitDidFinish: debouncedCommitDidFinish
        )
    }

    func undo() -> KeyboardUndoRedoEdit? {
        manager.undo()
    }

    func redo() -> KeyboardUndoRedoEdit? {
        manager.redo()
    }

    func updateLastUndoTargetContext(_ context: KeyboardTextContextSnapshot?) {
        manager.updateLastUndoTargetContext(context)
    }

    func updateLastRedoTargetContext(_ context: KeyboardTextContextSnapshot?) {
        manager.updateLastRedoTargetContext(context)
    }

    @discardableResult
    func commitDeferredGroupIfNeeded(shouldDeferCommit: Bool) -> Bool {
        guard needsDeferredCommit else { return false }
        commitPendingGroup(shouldDeferCommit: shouldDeferCommit)
        return true
    }

    func commitPendingGroup(shouldDeferCommit: Bool) {
        guard !shouldDeferCommit else {
            needsDeferredCommit = true
            debounceTimer = nil
            return
        }

        manager.commitPendingGroup()
        needsDeferredCommit = false
        debounceTimer = nil
    }

    func commitPendingGroupIgnoringDeferral() {
        debounceTimer?.cancel()
        manager.commitPendingGroup()
        needsDeferredCommit = false
        debounceTimer = nil
    }

    func cancelDebounceTimer() {
        debounceTimer?.cancel()
        debounceTimer = nil
    }

    func removeAll() {
        cancelDebounceTimer()
        needsDeferredCommit = false
        manager.removeAll()
    }

    func performApplyingEdit(_ apply: () -> Bool) -> Bool {
        isApplyingEdit = true
        defer { isApplyingEdit = false }
        return apply()
    }

    func prepareForTextWillChange(
        inputIdentifier: ObjectIdentifier?,
        context: KeyboardTextContextSnapshot
    ) {
        pendingTextChangeContext = context
        pendingTextChangeInputIdentifier = inputIdentifier
    }

    func shouldInvalidateAfterTextChange(
        inputIdentifier nextIdentifier: ObjectIdentifier?,
        currentContext: KeyboardTextContextSnapshot
    ) -> Bool {
        defer {
            pendingTextChangeContext = nil
            pendingTextChangeInputIdentifier = nil
        }

        guard !isApplyingEdit else { return false }

        let didChangeTextInput = currentTextInputIdentifier != nil
        && nextIdentifier != nil
        && currentTextInputIdentifier != nextIdentifier

        if let nextIdentifier {
            currentTextInputIdentifier = nextIdentifier
        } else if currentTextInputIdentifier == nil {
            currentTextInputIdentifier = pendingTextChangeInputIdentifier
        }

        return didChangeTextInput
    }

    // MARK: - Private Methods

    private func scheduleDebounceCommit(
        shouldDeferCommit: @escaping () -> Bool,
        debouncedCommitDidFinish: @escaping () -> Void
    ) {
        debounceTimer?.cancel()
        debounceTimer = Just(())
            .delay(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.commitPendingGroup(shouldDeferCommit: shouldDeferCommit())
                debouncedCommitDidFinish()
            }
    }

}

// MARK: - Supporting Types

private struct KeyboardTextMutation {

    // MARK: - Properties

    var deletedText: String
    var insertedText: String
    var undoTargetContext: KeyboardTextContextSnapshot?
    var redoTargetContext: KeyboardTextContextSnapshot?

    var undoEdit: KeyboardUndoRedoEdit {
        KeyboardUndoRedoEdit(
            deleteCount: insertedText.count,
            insertText: deletedText,
            targetContext: undoTargetContext
        )
    }

    var redoEdit: KeyboardUndoRedoEdit {
        KeyboardUndoRedoEdit(
            deleteCount: deletedText.count,
            insertText: insertedText,
            targetContext: redoTargetContext
        )
    }

    var isNoop: Bool {
        return deletedText == insertedText
    }

    private var isPureInsertion: Bool {
        return deletedText.isEmpty && !insertedText.isEmpty
    }

    private var isPureDeletion: Bool {
        return !deletedText.isEmpty && insertedText.isEmpty
    }

    // MARK: - Internal Methods

    func shouldStartNewGroup(before other: KeyboardTextMutation) -> Bool {
        return (isPureInsertion && other.isPureDeletion)
        || (isPureDeletion && other.isPureInsertion)
    }

    mutating func merge(with other: KeyboardTextMutation) {
        if insertedText.isEmpty && other.insertedText.isEmpty {
            deletedText = other.deletedText + deletedText
            undoTargetContext = other.undoTargetContext
            return
        }

        if other.deletedText.isEmpty {
            insertedText.append(other.insertedText)
            undoTargetContext = other.undoTargetContext
            return
        }

        if insertedText.hasSuffix(other.deletedText) {
            insertedText.removeLast(other.deletedText.count)
            insertedText.append(other.insertedText)
            undoTargetContext = other.undoTargetContext
            return
        }

        if other.deletedText.hasSuffix(insertedText) {
            let additionallyDeletedCount = other.deletedText.count - insertedText.count
            let additionallyDeletedText = String(other.deletedText.prefix(additionallyDeletedCount))
            deletedText.append(additionallyDeletedText)
            insertedText = other.insertedText
            undoTargetContext = other.undoTargetContext
            return
        }

        commitSequentialReplacement(with: other)
    }

    // MARK: - Private Methods

    private mutating func commitSequentialReplacement(with other: KeyboardTextMutation) {
        deletedText.append(other.deletedText)
        insertedText.append(other.insertedText)
        undoTargetContext = other.undoTargetContext
    }
}
