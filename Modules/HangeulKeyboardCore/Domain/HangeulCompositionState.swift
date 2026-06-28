//
//  HangeulCompositionState.swift
//  HangeulKeyboardCore
//
//  Created by Codex on 6/3/26.
//

enum HangeulProxyEdit: Equatable {
    case none
    case insert(String)
    case delete(count: Int)
    case replace(deleteCount: Int, insertText: String)
}

struct HangeulCompositionTransition: Equatable {
    let proxyEdits: [HangeulProxyEdit]

    var proxyEdit: HangeulProxyEdit {
        return proxyEdits.last ?? .none
    }

    init(proxyEdit: HangeulProxyEdit) {
        proxyEdits = [proxyEdit]
    }

    init(proxyEdits: [HangeulProxyEdit]) {
        self.proxyEdits = proxyEdits
    }

    func appending(_ transition: HangeulCompositionTransition?) -> HangeulCompositionTransition {
        guard let transition else { return self }
        return HangeulCompositionTransition(proxyEdits: proxyEdits + transition.proxyEdits)
    }
}

struct HangeulDeleteTouchDownResult: Equatable {
    let deletedCharacter: Character?
    let transition: HangeulCompositionTransition
}

struct HangeulDeletePanResult: Equatable {
    let character: Character
    let shouldRestore: Bool
    let transition: HangeulCompositionTransition
}

struct HangeulCompositionState {

    // MARK: - Properties

    private(set) var committedBuffer: String = ""
    private(set) var composingBuffer: String = ""
    private(set) var lastInputText: String?
    private(set) var temporaryDeletedCharacters: [Character] = []

    private var protectedCommittedCount: Int = 0
    private var isPulledFromProtected: Bool = false
    private var shouldSkipNextDeletePanRestore: Bool = false
    private var nextDeletePanRestoreReplacement: Character?
    private var deleteTouchDownSnapshot: DeleteTouchDownSnapshot?

    var text: String {
        return committedBuffer + composingBuffer
    }

    var isCommittedProtected: Bool {
        return !committedBuffer.isEmpty && committedBuffer.count <= protectedCommittedCount
    }

    // MARK: - Internal Methods

    @discardableResult
    mutating func input(
        _ text: String,
        using processor: HangeulProcessable
    ) -> HangeulCompositionTransition {
        return applyCompositionResult(
            processor.inputWithRestore종성(
                글자Input: text,
                composing: composingBuffer,
                committedTail: String(committedBuffer.suffix(2)),
                isProtected: committedBuffer.count <= protectedCommittedCount
            )
        )
    }

    @discardableResult
    mutating func space(using processor: HangeulProcessable) -> HangeulCompositionTransition {
        let result = processor.inputSpace(composing: composingBuffer)
        switch result {
        case .commitCombination:
            committedBuffer.append(composingBuffer)
            composingBuffer.removeAll()
            protectedCommittedCount = committedBuffer.count
            lastInputText = nil
            isPulledFromProtected = false
            return HangeulCompositionTransition(proxyEdit: .none)

        case .insertSpace:
            clearAllBuffers()
            processor.reset한글조합()
            lastInputText = nil
            return HangeulCompositionTransition(proxyEdit: .insert(" "))
        }
    }

    @discardableResult
    mutating func delete(using processor: HangeulProcessable) -> HangeulCompositionTransition {
        var transition: HangeulCompositionTransition

        if !composingBuffer.isEmpty {
            let oldComposingCount = composingBuffer.count
            let deleteResult = processor.deleteWithRestore종성(
                composing: composingBuffer,
                committedTail: String(committedBuffer.suffix(2)),
                isProtected: committedBuffer.count <= protectedCommittedCount
            )

            let totalDeleteCount = oldComposingCount + deleteResult.consumedCommittedCount
            transition = HangeulCompositionTransition(
                proxyEdit: .replace(deleteCount: totalDeleteCount, insertText: deleteResult.composing)
            )

            applyConsumedCommitted(count: deleteResult.consumedCommittedCount)
            composingBuffer = deleteResult.composing

            if composingBuffer.isEmpty {
                transition = transition.appending(pullFromCommittedIfNeeded(using: processor))
            }
        } else if !committedBuffer.isEmpty {
            let lastCommitted = committedBuffer.last!

            if lastCommitted.isHangeul {
                let isProtected = committedBuffer.count <= protectedCommittedCount

                committedBuffer.removeLast()
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)

                let deleteResult = processor.deleteWithRestore종성(
                    composing: String(lastCommitted),
                    committedTail: String(committedBuffer.suffix(2)),
                    isProtected: committedBuffer.count <= protectedCommittedCount
                )

                let totalDeleteCount = 1 + deleteResult.consumedCommittedCount
                transition = HangeulCompositionTransition(
                    proxyEdit: .replace(deleteCount: totalDeleteCount, insertText: deleteResult.composing)
                )

                applyConsumedCommitted(count: deleteResult.consumedCommittedCount)
                composingBuffer = deleteResult.composing

                if composingBuffer.isEmpty {
                    processor.reset한글조합()
                } else if !isProtected {
                    processor.start한글조합()
                }
            } else {
                committedBuffer.removeLast()
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                processor.reset한글조합()
                transition = HangeulCompositionTransition(proxyEdit: .delete(count: 1))
            }
        } else {
            processor.reset한글조합()
            transition = HangeulCompositionTransition(proxyEdit: .delete(count: 1))
        }

        lastInputText = nil
        return transition
    }

    @discardableResult
    mutating func repeatInsert(using processor: HangeulProcessable) -> HangeulCompositionTransition {
        guard let lastInputText else {
            return HangeulCompositionTransition(proxyEdit: .none)
        }

        return repeatInsert(lastInputText, using: processor)
    }

    @discardableResult
    mutating func repeatInsert(
        _ text: String,
        using _: HangeulProcessable
    ) -> HangeulCompositionTransition {
        if !composingBuffer.isEmpty {
            committedBuffer.append(composingBuffer)
            composingBuffer.removeAll()
        }

        composingBuffer = text
        lastInputText = text
        isPulledFromProtected = false
        return HangeulCompositionTransition(proxyEdit: .insert(text))
    }

    @discardableResult
    mutating func repeatDelete(using processor: HangeulProcessable) -> HangeulCompositionTransition {
        if !composingBuffer.isEmpty {
            composingBuffer.removeLast()
            if composingBuffer.isEmpty {
                processor.reset한글조합()
            }
        } else if !committedBuffer.isEmpty {
            committedBuffer.removeLast()
            protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
            processor.reset한글조합()
        } else {
            processor.reset한글조합()
        }

        lastInputText = nil
        return HangeulCompositionTransition(proxyEdit: .delete(count: 1))
    }

    @discardableResult
    mutating func deleteButtonTouchDown(
        using processor: HangeulProcessable
    ) -> HangeulDeleteTouchDownResult {
        let deletedCharacter = text.last

        if let deletedCharacter {
            temporaryDeletedCharacters.append(deletedCharacter)
        }

        beginDeleteButtonTouchDown()
        let transition = delete(using: processor)
        endDeleteButtonTouchDown()

        return HangeulDeleteTouchDownResult(
            deletedCharacter: deletedCharacter,
            transition: transition
        )
    }

    mutating func beginDeleteButtonTouchDown() {
        deleteTouchDownSnapshot = DeleteTouchDownSnapshot(
            hadComposingBeforeDelete: !composingBuffer.isEmpty,
            composingBeforeDelete: composingBuffer,
            committedBeforeDelete: committedBuffer
        )
    }

    mutating func endDeleteButtonTouchDown() {
        guard let snapshot = deleteTouchDownSnapshot else { return }

        shouldSkipNextDeletePanRestore = snapshot.hadComposingBeforeDelete && !composingBuffer.isEmpty
        nextDeletePanRestoreReplacement = deletePanRestoreReplacementAfterDeleteTouchDown(
            composingBeforeDelete: snapshot.composingBeforeDelete,
            committedBeforeDelete: snapshot.committedBeforeDelete
        )
        deleteTouchDownSnapshot = nil
    }

    mutating func cancelDeleteButtonTouchDown() {
        deleteTouchDownSnapshot = nil
        shouldSkipNextDeletePanRestore = false
        nextDeletePanRestoreReplacement = nil
    }

    @discardableResult
    mutating func deleteButtonPanDelete(
        using processor: HangeulProcessable
    ) -> HangeulDeletePanResult? {
        let shouldSkipRestore = shouldSkipNextDeletePanRestore
        let restoreReplacement = nextDeletePanRestoreReplacement
        shouldSkipNextDeletePanRestore = false
        nextDeletePanRestoreReplacement = nil

        let deletedCharacter: Character?
        let shouldRestoreDeletedCharacter: Bool

        if !composingBuffer.isEmpty {
            var character = composingBuffer.removeLast()
            if shouldSkipRestore, let restoreReplacement {
                character = restoreReplacement
                shouldRestoreDeletedCharacter = true
            } else {
                shouldRestoreDeletedCharacter = !shouldSkipRestore
            }
            deletedCharacter = character
            if shouldRestoreDeletedCharacter {
                temporaryDeletedCharacters.append(character)
            }
            isPulledFromProtected = false

            if composingBuffer.isEmpty {
                processor.reset한글조합()
            } else {
                processor.start한글조합()
            }
        } else if !committedBuffer.isEmpty {
            let character = committedBuffer.removeLast()
            deletedCharacter = character
            shouldRestoreDeletedCharacter = true
            temporaryDeletedCharacters.append(character)
            protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
            isPulledFromProtected = false
            processor.reset한글조합()
        } else {
            deletedCharacter = nil
            shouldRestoreDeletedCharacter = true
            isPulledFromProtected = false
            processor.reset한글조합()
        }

        lastInputText = nil

        guard let deletedCharacter else { return nil }
        return HangeulDeletePanResult(
            character: deletedCharacter,
            shouldRestore: shouldRestoreDeletedCharacter,
            transition: HangeulCompositionTransition(proxyEdit: .delete(count: 1))
        )
    }

    @discardableResult
    mutating func deleteButtonPanRestore(
        _ character: Character,
        using processor: HangeulProcessable
    ) -> HangeulCompositionTransition {
        shouldSkipNextDeletePanRestore = false
        nextDeletePanRestoreReplacement = nil

        let text = String(character)
        if !composingBuffer.isEmpty {
            committedBuffer.append(composingBuffer)
            composingBuffer.removeAll()
            isPulledFromProtected = false
        }

        if character.isHangeul {
            composingBuffer = text
            isPulledFromProtected = false
            processor.start한글조합()
        } else {
            committedBuffer.append(text)
            processor.reset한글조합()
        }

        lastInputText = text
        return HangeulCompositionTransition(proxyEdit: .insert(text))
    }

    @discardableResult
    mutating func deleteButtonPanRestoreLast(
        using processor: HangeulProcessable
    ) -> HangeulCompositionTransition? {
        guard let character = temporaryDeletedCharacters.popLast() else { return nil }
        return deleteButtonPanRestore(character, using: processor)
    }

    mutating func finishDeleteButtonPan() {
        shouldSkipNextDeletePanRestore = false
        nextDeletePanRestoreReplacement = nil
        temporaryDeletedCharacters.removeAll()
    }

    @discardableResult
    mutating func finishRepeatDelete(
        using processor: HangeulProcessable
    ) -> HangeulCompositionTransition? {
        guard composingBuffer.isEmpty, !committedBuffer.isEmpty else { return nil }

        let lastCommitted = committedBuffer.last!
        let lastText = String(lastCommitted)
        guard lastCommitted.isHangeul else { return nil }

        let isProtected = committedBuffer.count <= protectedCommittedCount
        committedBuffer.removeLast()
        protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
        composingBuffer = lastText
        isPulledFromProtected = isProtected

        if !isProtected {
            processor.start한글조합()
        }

        return HangeulCompositionTransition(
            proxyEdit: .replace(deleteCount: 1, insertText: lastText)
        )
    }

    mutating func clearAllBuffers() {
        committedBuffer.removeAll()
        composingBuffer.removeAll()
        protectedCommittedCount = 0
        isPulledFromProtected = false
        shouldSkipNextDeletePanRestore = false
        nextDeletePanRestoreReplacement = nil
        deleteTouchDownSnapshot = nil
        temporaryDeletedCharacters.removeAll()
        lastInputText = nil
    }

    mutating func setDeleteDragState(
        committed: String,
        composing: String,
        deletedCharacters: [Character],
        shouldSkipNextDeletePanRestore: Bool = true,
        nextDeletePanRestoreReplacement: Character? = nil
    ) {
        committedBuffer = committed
        composingBuffer = composing
        temporaryDeletedCharacters = deletedCharacters
        self.shouldSkipNextDeletePanRestore = shouldSkipNextDeletePanRestore
        self.nextDeletePanRestoreReplacement = nextDeletePanRestoreReplacement
        protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
    }
}

private struct DeleteTouchDownSnapshot {
    let hadComposingBeforeDelete: Bool
    let composingBeforeDelete: String
    let committedBeforeDelete: String
}

// MARK: - Private Methods

private extension HangeulCompositionState {

    mutating func applyCompositionResult(
        _ result: CompositionResult
    ) -> HangeulCompositionTransition {
        let oldComposing = composingBuffer
        let oldComposingCount = oldComposing.count

        let proxyEdit: HangeulProxyEdit
        if result.committed == oldComposing && result.consumedCommittedCount == 0 {
            committedBuffer.append(result.committed)

            if isPulledFromProtected {
                protectedCommittedCount = committedBuffer.count
                isPulledFromProtected = false
            }

            composingBuffer = result.composing
            proxyEdit = result.composing.isEmpty ? .none : .insert(result.composing)
        } else {
            let totalDeleteCount = oldComposingCount + result.consumedCommittedCount
            let textToInsert = result.committed + result.composing
            proxyEdit = .replace(deleteCount: totalDeleteCount, insertText: textToInsert)

            applyConsumedCommitted(count: result.consumedCommittedCount)

            if !result.committed.isEmpty {
                committedBuffer.append(result.committed)

                if isPulledFromProtected {
                    protectedCommittedCount = committedBuffer.count
                    isPulledFromProtected = false
                }
            } else {
                isPulledFromProtected = false
            }

            composingBuffer = result.composing
        }

        lastInputText = result.input글자
        return HangeulCompositionTransition(proxyEdit: proxyEdit)
    }

    mutating func applyConsumedCommitted(count: Int) {
        guard count > 0 else { return }

        for _ in 0..<count {
            committedBuffer.removeLast()
        }

        protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
    }

    mutating func pullFromCommittedIfNeeded(
        using processor: HangeulProcessable
    ) -> HangeulCompositionTransition? {
        guard composingBuffer.isEmpty, !committedBuffer.isEmpty else {
            if composingBuffer.isEmpty {
                processor.reset한글조합()
            }
            return nil
        }

        let lastCommitted = committedBuffer.last!
        let lastText = String(lastCommitted)

        if lastCommitted.isHangeul {
            let isProtected = committedBuffer.count <= protectedCommittedCount

            committedBuffer.removeLast()
            protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
            composingBuffer = lastText
            isPulledFromProtected = isProtected

            if !isProtected {
                processor.start한글조합()
            }

            return HangeulCompositionTransition(
                proxyEdit: .replace(deleteCount: 1, insertText: lastText)
            )
        } else {
            processor.reset한글조합()
            return nil
        }
    }

    func deletePanRestoreReplacementAfterDeleteTouchDown(
        composingBeforeDelete: String,
        committedBeforeDelete: String
    ) -> Character? {
        guard shouldSkipNextDeletePanRestore else { return nil }

        let remainingBeforeDelete = String(composingBeforeDelete.dropLast())
        if remainingBeforeDelete.count == 1,
           composingBuffer.count == 1,
           remainingBeforeDelete != composingBuffer {
            return remainingBeforeDelete.last
        }

        let consumedCommittedCount = committedBeforeDelete.count - committedBuffer.count
        guard consumedCommittedCount == 1,
              composingBuffer.count == 1,
              let consumedCommitted = committedBeforeDelete.last else {
            return nil
        }

        return consumedCommitted
    }
}
