//
//  HangeulDeleteButtonDragScenarioTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 5/21/26.
//

import Testing

@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

/// 삭제 버튼 touchDown·드래그는 production `TextDeletionCoordinator`가 복구 스택과 함께 처리하고,
/// 한글 VC가 오버라이드하는 host 메서드는 production `HangeulCompositionState`가 처리한다
@Suite("한글 삭제 버튼 드래그 TextDeletionCoordinator + HangeulCompositionState 시나리오", .sharedUserDefaults)
@MainActor
struct HangeulDeleteButtonDragScenarioTests {

    // MARK: - Properties

    /// 입력기마다 같은 시나리오를 돌리기 위한 구분
    enum InputMethod: CaseIterable {
        case dubeolsik
        case cheonjiin
        case naratgeul
    }

    private let automata: HangeulAutomataProtocol = HangeulAutomata()

    private let 천 = "ㆍ"
    private let 지 = "ㅡ"
    private let 인 = "ㅣ"

    // MARK: - 전체 삭제/복구 후 버퍼 동기화

    @Test("삭제 버튼 드래그 복구: '동해물과' 전체 삭제 후 복구", arguments: InputMethod.allCases)
    func test삭제버튼드래그_전체복구후_버퍼동기화(_ inputMethod: InputMethod) {
        assert전체복구후_버퍼동기화(make동해물과Harness(inputMethod))
    }

    // MARK: - touchDown 선삭제 후 pan 복구 중복 방지

    @Test("삭제 버튼 드래그 복구: touchDown 선삭제 후 pan 복구가 중복되지 않음", arguments: InputMethod.allCases)
    func test삭제버튼드래그_touchDown선삭제후_복구중복방지(_ inputMethod: InputMethod) {
        assertTouchDown선삭제후_복구중복방지(make동해물과Harness(inputMethod))
    }

    @Test("두벌식 삭제 버튼 드래그 복구: '동해물고' touchDown 선삭제 후 전체 복구")
    func test두벌식_삭제버튼드래그_동해물고_touchDown선삭제후_전체복구() {
        let sim = HangeulDeleteButtonDragSimulator(
            processor: DubeolsikProcessor(automata: automata)
        )

        inputDubeolsik동해물고(into: sim)
        assertTouchDown선삭제후_전체복구(sim, expectedTouchDownText: "동해묽", expectedRestoredText: "동해물고")
    }

    @Test("두벌식 삭제 버튼 드래그 복구: '동해물과' touchDown으로 생긴 '동해물고' 전체 복구")
    func test두벌식_삭제버튼드래그_동해물과_touchDown후_동해물고_전체복구() {
        let sim = HangeulDeleteButtonDragSimulator(
            processor: DubeolsikProcessor(automata: automata)
        )

        inputDubeolsik동해물과(into: sim)
        sim.deleteButtonTouchDown()
        #expect(sim.text == "동해물고")

        while !sim.text.isEmpty {
            sim.dragDeleteLeft()
        }
        #expect(sim.text == "")

        for _ in "동해물과" {
            sim.dragRestoreRight()
        }
        #expect(sim.text == "동해물과", "touchDown으로 생긴 '동해물고' 상태도 전체 복구 시 '물'이 빠지면 안 됩니다.")
    }

    @Test("두벌식 삭제 버튼 드래그 복구: '동해물거ㅓ' touchDown 후 전체 복구")
    func test두벌식_삭제버튼드래그_동해물거ㅓ_touchDown선삭제후_전체복구() {
        let sim = HangeulDeleteButtonDragSimulator(
            processor: DubeolsikProcessor(automata: automata)
        )

        inputDubeolsik동해물거ㅓ(into: sim)
        assertTouchDown선삭제후_전체복구(sim, expectedTouchDownText: "동해물거", expectedRestoredText: "동해물거ㅓ")
    }
}

// MARK: - Assertions

private extension HangeulDeleteButtonDragScenarioTests {
    /// 해당 입력기의 키 입력으로 '동해물과'를 만든 simulator
    func make동해물과Harness(_ inputMethod: InputMethod) -> HangeulDeleteButtonDragSimulator {
        switch inputMethod {
        case .dubeolsik:
            let sim = HangeulDeleteButtonDragSimulator(processor: DubeolsikProcessor(automata: automata))
            inputDubeolsik동해물과(into: sim)
            return sim
        case .cheonjiin:
            let sim = HangeulDeleteButtonDragSimulator(processor: CheonjiinProcessor(automata: automata))
            inputCheonjiin동해물과(into: sim)
            return sim
        case .naratgeul:
            let sim = HangeulDeleteButtonDragSimulator(processor: NaratgeulProcessor(automata: automata))
            inputNaratgeul동해물과(into: sim)
            return sim
        }
    }

    func assert전체복구후_버퍼동기화(_ sim: HangeulDeleteButtonDragSimulator) {
        #expect(sim.text == "동해물과")

        sim.dragDeleteLeft()
        #expect(sim.text == "동해물", "삭제 버튼 드래그는 조합 단위가 아니라 화면의 한 글자 단위로 삭제해야 합니다.")

        sim.dragRestoreRight()
        #expect(sim.text == "동해물과")

        for _ in 0..<4 {
            sim.dragDeleteLeft()
        }
        #expect(sim.text == "")

        for _ in 0..<4 {
            sim.dragRestoreRight()
        }
        #expect(sim.text == "동해물과")

        sim.input("ㅇ")
        #expect(sim.text == "동해물광", "드래그 복구 후 내부 composingBuffer가 마지막 글자와 동기화되어야 합니다.")
    }

    func assertTouchDown선삭제후_복구중복방지(_ sim: HangeulDeleteButtonDragSimulator) {
        #expect(sim.text == "동해물과")

        sim.deleteButtonTouchDown()
        #expect(sim.text == "동해물고", "삭제 버튼은 touchDown에서 단일 삭제를 먼저 실행해야 합니다.")

        for _ in 0..<4 {
            sim.dragDeleteLeft()
        }
        #expect(sim.text == "")

        for _ in 0..<4 {
            sim.dragRestoreRight()
        }
        #expect(sim.text == "동해물과", "touchDown 삭제와 pan 복구 버퍼가 섞여도 '고'가 중복 복구되면 안 됩니다.")
    }

    func assertTouchDown선삭제후_전체복구(
        _ sim: HangeulDeleteButtonDragSimulator,
        expectedTouchDownText: String,
        expectedRestoredText: String
    ) {
        #expect(sim.text == expectedRestoredText)

        sim.deleteButtonTouchDown()
        #expect(sim.text == expectedTouchDownText)

        while !sim.text.isEmpty {
            sim.dragDeleteLeft()
        }
        #expect(sim.text == "")

        for _ in expectedRestoredText {
            sim.dragRestoreRight()
        }
        #expect(sim.text == expectedRestoredText, "touchDown 삭제 후 전체 드래그 삭제/복구가 원문을 보존해야 합니다.")
    }
}

// MARK: - Input Helpers

private extension HangeulDeleteButtonDragScenarioTests {

    func inputDubeolsik동해물과(into sim: HangeulDeleteButtonDragSimulator) {
        ["ㄷ", "ㅗ", "ㅇ", "ㅎ", "ㅐ", "ㅁ", "ㅜ", "ㄹ", "ㄱ", "ㅗ", "ㅏ"].forEach {
            sim.input($0)
        }
    }

    func inputDubeolsik동해물고(into sim: HangeulDeleteButtonDragSimulator) {
        ["ㄷ", "ㅗ", "ㅇ", "ㅎ", "ㅐ", "ㅁ", "ㅜ", "ㄹ", "ㄱ", "ㅗ"].forEach {
            sim.input($0)
        }
    }

    func inputDubeolsik동해물거ㅓ(into sim: HangeulDeleteButtonDragSimulator) {
        ["ㄷ", "ㅗ", "ㅇ", "ㅎ", "ㅐ", "ㅁ", "ㅜ", "ㄹ", "ㄱ", "ㅓ", "ㅓ"].forEach {
            sim.input($0)
        }
    }

    func inputCheonjiin동해물과(into sim: HangeulDeleteButtonDragSimulator) {
        [
            "ㄷ", 천, 지, "ㅇ",             // 동
            "ㅅ", "ㅅ", 인, 천, 인,        // 해
            "ㅇ", "ㅇ", 지, 천, "ㄴ", "ㄴ", // 물
            "ㄱ", 천, 지, 인, 천          // 과
        ].forEach {
            sim.input($0)
        }
    }

    func inputNaratgeul동해물과(into sim: HangeulDeleteButtonDragSimulator) {
        [
            "ㄴ", "획", "ㅗ", "ㅇ",  // 동
            "ㅇ", "획", "ㅏ", "ㅣ", // 해
            "ㅁ", "ㅜ", "ㄹ",       // 물
            "ㄱ", "ㅗ", "ㅏ"        // 과
        ].forEach {
            sim.input($0)
        }
    }
}

// MARK: - Test Helpers

/// 키 입력은 `HangeulCompositionState`에 바로 넣고, 삭제 버튼 touchDown·드래그는 `TextDeletionCoordinator`로 보낸다.
/// 매 동작 뒤에는 입력창처럼 `textDidChange`를 보낸다
@MainActor
private final class HangeulDeleteButtonDragSimulator {

    // MARK: - Properties

    private let host: HangeulTextDeletionHost
    private let coordinator: TextDeletionCoordinator
    private let button = DeleteButton(keyboard: .dubeolsik)

    /// 현재 화면에 표시되는 전체 텍스트(조합 상태 기준)
    var text: String { host.text }

    // MARK: - Initializer

    init(processor: HangeulProcessable) {
        let proxy = CountingTextDocumentProxy()
        proxy.beforeInput = ""
        host = HangeulTextDeletionHost(processor: processor, proxy: proxy)
        coordinator = TextDeletionCoordinator(
            deleteDragIndicatorView: CursorDragIndicatorView(
                symbolName: CursorDragIndicatorSymbolFactory.deleteSymbolName
            ),
            suggestionController: FakeSuggestionService(),
            keyboardSettingsManager: .shared,
            host: host
        )
        host.coordinator = coordinator
    }

    // MARK: - Internal Methods

    /// 글자 입력
    func input(_ character: String) {
        host.input(character)
    }

    /// 삭제 버튼 touchDown. 손은 떼지 않은 채 드래그로 이어진다
    func deleteButtonTouchDown() {
        coordinator.performTouchDown(for: button)
        sendTextDidChange()
    }

    /// 삭제 버튼 왼쪽 드래그
    func dragDeleteLeft() {
        coordinator.handlePan(to: .left)
        sendTextDidChange()
    }

    /// 삭제 버튼 오른쪽 드래그
    func dragRestoreRight() {
        coordinator.handlePan(to: .right)
        sendTextDidChange()
    }

    // MARK: - Private Methods

    private func sendTextDidChange() {
        coordinator.completeAfterTextChange(currentContext: host.textDocument.contextSnapshot)
    }
}

/// `HangeulKeyboardCoreViewController`가 오버라이드한 삭제 host 메서드를 따르는 host.
/// 조합 상태는 production `HangeulCompositionState`가 갖고, 프록시 쓰기와 capture는 상위 가짜의 VC 래퍼 계약을 쓴다
@MainActor
private final class HangeulTextDeletionHost: RecordingTextDeletionHost {

    // MARK: - Properties

    private let processor: HangeulProcessable
    private var state = HangeulCompositionState()

    var text: String { state.text }

    // MARK: - Initializer

    init(processor: HangeulProcessable, proxy: CountingTextDocumentProxy) {
        self.processor = processor
        super.init(proxy: proxy)
    }

    // MARK: - Internal Methods

    func input(_ character: String) {
        apply(state.input(character, using: processor))
    }

    // MARK: - TextDeletionHost

    override func textInteractionWillPerform(button: TextInteractable) {
        if button is DeleteButton {
            state.beginDeleteButtonTouchDown()
        } else {
            state.cancelDeleteButtonTouchDown()
        }
        super.textInteractionWillPerform(button: button)
    }

    override func textInteractionDidPerform(button: TextInteractable) {
        super.textInteractionDidPerform(button: button)
        if button is DeleteButton {
            state.endDeleteButtonTouchDown()
        } else {
            state.cancelDeleteButtonTouchDown()
        }
    }

    override func deleteBackward() {
        apply(state.delete(using: processor))
    }

    override func repeatDeleteBackward() {
        apply(state.repeatDelete(using: processor))
    }

    override func deleteButtonPanDeleteText(hasPendingRestoreText _: Bool) -> (character: Character, shouldRestore: Bool)? {
        if let result = state.deleteButtonPanDelete(using: processor) {
            apply(result.transition)
            return (result.character, result.shouldRestore)
        }

        guard let deletedCharacter = coordinator?.panPreviousCharacter else { return nil }
        deleteText()
        return (deletedCharacter, true)
    }

    override func deleteButtonPanRestoreText(_ character: Character) {
        apply(state.deleteButtonPanRestore(character, using: processor))
    }

    override func deleteButtonPanDidStop() {
        super.deleteButtonPanDidStop()
        state.finishDeleteButtonPan()
    }

    // MARK: - Private Methods

    /// VC `applyCompositionTransition(_:)`과 같은 순서로 프록시에 반영한다
    private func apply(_ transition: HangeulCompositionTransition) {
        for proxyEdit in transition.proxyEdits {
            switch proxyEdit {
            case .none:
                break
            case .insert(let text):
                insertText(text)
            case .delete(let count):
                if count == 1 {
                    deleteText()
                } else {
                    replaceText(deleteCount: count, insert: "")
                }
            case .replace(let deleteCount, let insertText):
                replaceText(deleteCount: deleteCount, insert: insertText)
            }
        }
    }
}
