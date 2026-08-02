//
//  HangeulCompositionTestHarness.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 3/8/26.
//

import Testing

@testable import HangeulKeyboardCore

/// production `HangeulCompositionState` 기반 입력 상태 시나리오를 실행하는 테스트 harness
///
/// `textDocumentProxy` 등 iOS 시스템 의존성 없이 production 조합 상태 전이를 직접 검증합니다.
final class HangeulCompositionTestHarness {

    // MARK: - Properties

    private let processor: HangeulProcessable
    private var state = HangeulCompositionState()

    /// 조합이 완료되어 더 이상 변경되지 않는 문자열
    var committedBuffer: String { state.committedBuffer }
    /// 현재 오토마타가 조합 중인 문자열
    var composingBuffer: String { state.composingBuffer }
    /// 현재 화면에 표시되는 전체 텍스트
    var text: String { state.text }
    // MARK: - Initializer

    init(processor: HangeulProcessable) {
        self.processor = processor
    }

    // MARK: - Internal Methods

    /// 글자 입력
    func input(_ char: String) {
        state.input(char, using: processor)
    }

    /// 스페이스 입력
    func space() {
        state.space(using: processor)
    }

    /// 삭제
    func delete() {
        state.delete(using: processor)
    }

    /// 반복 입력
    func repeatInsert(_ char: String) {
        state.repeatInsert(char, using: processor)
    }

    /// 반복 삭제
    func repeatDelete() {
        state.repeatDelete(using: processor)
    }

    /// 삭제 버튼 touchDown
    func deleteButtonTouchDown() {
        state.deleteButtonTouchDown(using: processor)
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

    /// 삭제 버튼 왼쪽 드래그
    func dragDeleteLeft() {
        state.deleteButtonPanDelete(using: processor)
    }

    /// 삭제 버튼 오른쪽 드래그
    func dragRestoreRight() {
        state.deleteButtonPanRestoreLast(using: processor)
    }

    /// 반복 삭제 종료 후 끌어오기
    func finishRepeatDelete() {
        state.finishRepeatDelete(using: processor)
    }

    /// 반복 입력 시작 시 조합
    func repeatStart(_ primaryKey: String) {
        state.input(primaryKey, using: processor)
    }
}
