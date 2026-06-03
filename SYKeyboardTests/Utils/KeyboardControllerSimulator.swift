//
//  KeyboardControllerSimulator.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 3/8/26.
//

import Testing

@testable import HangeulKeyboardCore

/// `HangeulKeyboardCoreViewController`의 버퍼 관리 로직을 시뮬레이션하는 테스트 헬퍼
///
/// `textDocumentProxy` 등 iOS 시스템 의존성 없이 컨트롤러의 핵심 상태 전이를 검증합니다.
/// 실제 상태 전이는 `HangeulCompositionState`를 사용하여 controller와 simulator가 같은 규칙을 공유합니다.
final class KeyboardControllerSimulator {

    // MARK: - Properties

    private let processor: HangeulProcessable
    private var state = HangeulCompositionState()

    /// 조합이 완료되어 더 이상 변경되지 않는 문자열
    var committedBuffer: String { state.committedBuffer }
    /// 현재 오토마타가 조합 중인 문자열
    var composingBuffer: String { state.composingBuffer }
    /// 현재 화면에 표시되는 전체 텍스트
    var text: String { state.text }
    /// 자동완성 UI의 현재 단어 표시값 시뮬레이션
    private(set) var suggestionCurrentWord: String?

    // MARK: - Initializer

    init(automata _: HangeulAutomataProtocol, processor: HangeulProcessable) {
        self.processor = processor
    }

    // MARK: - Internal Methods

    /// 글자 입력 (컨트롤러의 `insertPrimaryKeyText` 시뮬레이션)
    func input(_ char: String) {
        state.input(char, using: processor)
        updateSuggestionCurrentWord()
    }

    /// 스페이스 입력 (컨트롤러의 `insertSpaceText` 시뮬레이션)
    func space() {
        state.space(using: processor)
    }

    /// 삭제 (컨트롤러의 `deleteBackward` 시뮬레이션)
    func delete() {
        state.delete(using: processor)
    }

    /// 반복 입력 (컨트롤러의 `repeatInsertPrimaryKeyText` 시뮬레이션)
    func repeatInsert(_ char: String) {
        state.repeatInsert(char, using: processor)
    }

    /// 반복 삭제 (컨트롤러의 `repeatDeleteBackward` 시뮬레이션)
    func repeatDelete() {
        state.repeatDelete(using: processor)
    }

    /// 삭제 버튼 touchDown (컨트롤러의 단일 삭제 액션 시뮬레이션)
    func deleteButtonTouchDown() {
        state.deleteButtonTouchDown(using: processor)
        updateSuggestionCurrentWord()
    }

    /// 삭제 버튼 드래그 중간 상태 세팅 (회귀 테스트용)
    func setDeleteDragStateForTesting(
        committed: String,
        composing: String,
        deletedCharacters: [Character],
        shouldSkipNextDeletePanRestore: Bool = true,
        nextDeletePanRestoreReplacement: Character? = nil
    ) {
        state.setDeleteDragState(
            committed: committed,
            composing: composing,
            deletedCharacters: deletedCharacters,
            shouldSkipNextDeletePanRestore: shouldSkipNextDeletePanRestore,
            nextDeletePanRestoreReplacement: nextDeletePanRestoreReplacement
        )
    }

    /// 삭제 버튼 왼쪽 드래그 (컨트롤러의 `deleteButtonPanDeleteText` 시뮬레이션)
    func dragDeleteLeft() {
        state.deleteButtonPanDelete(using: processor)
        updateSuggestionCurrentWord()
    }

    /// 삭제 버튼 오른쪽 드래그 (컨트롤러의 `deleteButtonPanRestoreText` 시뮬레이션)
    func dragRestoreRight() {
        state.deleteButtonPanRestoreLast(using: processor)
        updateSuggestionCurrentWord()
    }

    /// 반복 삭제 종료 후 끌어오기 (컨트롤러의 `repeatTextInteractionDidPerform` 시뮬레이션)
    func finishRepeatDelete() {
        state.finishRepeatDelete(using: processor)
    }

    /// 반복 입력 시작 시 조합 (컨트롤러의 `insertPrimaryKeyText`에서 repeat 시작 시뮬레이션)
    func repeatStart(_ primaryKey: String) {
        state.input(primaryKey, using: processor)
    }
}

// MARK: - Private Methods

private extension KeyboardControllerSimulator {

    /// 자동완성 UI의 현재 단어 표시를 갱신합니다.
    func updateSuggestionCurrentWord() {
        suggestionCurrentWord = text.isEmpty || text.last?.isWhitespace == true ? nil : text
    }
}
