//
//  RecordingTextDeletionHost.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

@testable import SYKeyboardCore

/// VC의 래퍼 계약을 흉내 내는 host: 프록시에 쓰고, 지운 글자를 Coordinator의 `captureMutation`에 넘기며,
/// 반복 틱·touchDown 요청은 Coordinator로 되돌려 보낸다.
///
/// 이 계약(`deleteText()`의 override·reliability 처리)의 권위는 VC를 실제로 거치는
/// `BaseKeyboardViewControllerDeleteUndoBehaviorTests`에 있다. VC 쪽 계약이 바뀌면 그 suite가 먼저 깨지고,
/// 이 가짜도 같이 고쳐야 한다. 여기서는 Coordinator가 host를 부르는 순서와 프록시 쓰기만 단언한다.
///
/// `TextDeletionCoordinatorTests`가 쓰고, 한글 VC처럼 삭제 메서드를 오버라이드하는 host는 이 클래스를 상속한다
/// (`HangeulDeleteButtonDragScenarioTests`)
@MainActor
class RecordingTextDeletionHost: TextDeletionHost {
    var calls: [String] = []
    /// 파이프라인이 capture하지 않아 undo에 바로 기록됐을 편집
    var uncapturedEdits: [String] = []
    /// `deleteText()`가 `takePanDeletedTextOverride()`로 받은 값
    var panDeletedTextOverrides: [String?] = []
    var currentInputBuffer = ""
    var isViewInWindow = true
    let textDocument: CachingTextDocumentProxy
    weak var coordinator: TextDeletionCoordinator?

    init(proxy: CountingTextDocumentProxy) {
        textDocument = CachingTextDocumentProxy { proxy }
    }

    /// VC처럼 삭제를 포함한 모든 입력 전에 pan 복구 상태를 비운다
    func textInteractionWillPerform(button: TextInteractable) {
        calls.append("textInteractionWillPerform")
        coordinator?.clearPanRestoreState()
    }
    func textInteractionDidPerform(button: TextInteractable) { calls.append("textInteractionDidPerform") }
    func deleteBackward() { calls.append("deleteBackward"); performSingleDelete() }
    func repeatDeleteBackward() { calls.append("repeatDeleteBackward"); performSingleDelete() }
    func deleteText() { calls.append("deleteText"); performSingleDelete() }

    func replaceText(deleteCount: Int, insert text: String) {
        calls.append("replaceText(\(deleteCount), \(text))")
        let deletedText = String((textDocument.documentContextBeforeInput ?? "").suffix(deleteCount))
        for _ in 0..<deleteCount { textDocument.deleteBackward() }
        if !text.isEmpty { textDocument.insertText(text) }
        capture(deletedText: deletedText, insertedText: text, reliability: .authoritative)
    }

    func deleteButtonPanDeleteText(hasPendingRestoreText: Bool) -> (character: Character, shouldRestore: Bool)? {
        calls.append("deleteButtonPanDeleteText(\(hasPendingRestoreText))")
        // Base VC의 기본 구현과 같다: 모델 글자가 없으면 nil, 있으면 deleteText()
        guard let character = coordinator?.panPreviousCharacter else { return nil }
        deleteText()
        return (character, true)
    }

    func deleteButtonPanRestoreText(_ character: Character) {
        calls.append("deleteButtonPanRestoreText(\(character))")
        insertText(String(character))
    }

    /// VC `insertText(_:)`의 계약: 넣은 글자를 authoritative로 capture한다
    func insertText(_ text: String) {
        textDocument.insertText(text)
        capture(deletedText: "", insertedText: text, reliability: .authoritative)
    }

    func deleteButtonPanDidStop() { calls.append("deleteButtonPanDidStop") }

    func performRepeatTextInteraction(for button: TextInteractable) {
        calls.append("performRepeatTextInteraction")
        coordinator?.performRepeatTick(for: button)
    }

    func performDeleteTextInteraction(for button: TextInteractable) {
        calls.append("performDeleteTextInteraction")
        coordinator?.performTouchDown(for: button)
    }

    func recordEditForUndo(deletedText: String, insertedText: String) {
        calls.append("recordEditForUndo(\(deletedText), \(insertedText))")
        capture(deletedText: deletedText, insertedText: insertedText, reliability: .authoritative)
    }

    func refreshSuggestions() { calls.append("refreshSuggestions") }

    /// VC `deleteText()`의 계약: 선택 영역이 비었으면 pan override, 아니면 선택 텍스트·앞 글자를 지운 글자로 삼는다
    private func performSingleDelete() {
        let selectedText = textDocument.selectedText
        let override = coordinator?.takePanDeletedTextOverride()
        panDeletedTextOverrides.append(override)
        let deletedText = ((selectedText ?? "").isEmpty ? override : nil)
            ?? KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: selectedText,
                documentContextBeforeInput: textDocument.documentContextBeforeInput
            )
        textDocument.deleteBackward()
        capture(
            deletedText: deletedText,
            insertedText: "",
            reliability: selectedText?.isEmpty == false ? .authoritative : .proxyContext
        )
    }

    private func capture(deletedText: String, insertedText: String, reliability: RepeatDeleteMutationReliability) {
        let captured = coordinator?.captureMutation(
            deletedText: deletedText, insertedText: insertedText, reliability: reliability
        ) ?? false
        if !captured { uncapturedEdits.append("\(deletedText)/\(insertedText)") }
    }
}
