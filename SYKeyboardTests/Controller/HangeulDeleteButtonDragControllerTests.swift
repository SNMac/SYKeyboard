//
//  HangeulDeleteButtonDragControllerTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 5/21/26.
//

import Testing

@testable import HangeulKeyboardCore

@Suite("한글 삭제 버튼 드래그 HangeulCompositionState 기반 입력 상태 시나리오")
struct HangeulDeleteButtonDragControllerTests {

    // MARK: - Properties

    private let automata: HangeulAutomataProtocol = HangeulAutomata()

    private let 천 = "ㆍ"
    private let 지 = "ㅡ"
    private let 인 = "ㅣ"

    // MARK: - 전체 삭제/복구 후 버퍼 동기화

    @Test("두벌식 삭제 버튼 드래그 복구: '동해물과' 전체 삭제 후 복구")
    func test두벌식_삭제버튼드래그_전체복구후_버퍼동기화() {
        let sim = HangeulCompositionTestHarness(
            processor: DubeolsikProcessor(automata: automata)
        )

        inputDubeolsik동해물과(into: sim)
        assert전체복구후_버퍼동기화(sim)
    }

    @Test("천지인 삭제 버튼 드래그 복구: '동해물과' 전체 삭제 후 복구")
    func test천지인_삭제버튼드래그_전체복구후_버퍼동기화() {
        let sim = HangeulCompositionTestHarness(
            processor: CheonjiinProcessor(automata: automata)
        )

        inputCheonjiin동해물과(into: sim)
        assert전체복구후_버퍼동기화(sim)
    }

    @Test("나랏글 삭제 버튼 드래그 복구: '동해물과' 전체 삭제 후 복구")
    func test나랏글_삭제버튼드래그_전체복구후_버퍼동기화() {
        let sim = HangeulCompositionTestHarness(
            processor: NaratgeulProcessor(automata: automata)
        )

        inputNaratgeul동해물과(into: sim)
        assert전체복구후_버퍼동기화(sim)
    }

    // MARK: - touchDown 선삭제 후 pan 복구 중복 방지

    @Test("두벌식 삭제 버튼 드래그 복구: touchDown 선삭제 후 pan 복구가 중복되지 않음")
    func test두벌식_삭제버튼드래그_touchDown선삭제후_복구중복방지() {
        let sim = HangeulCompositionTestHarness(
            processor: DubeolsikProcessor(automata: automata)
        )

        inputDubeolsik동해물과(into: sim)
        assertTouchDown선삭제후_복구중복방지(sim)
    }

    @Test("두벌식 삭제 버튼 드래그 복구: '동해물고' touchDown 선삭제 후 전체 복구")
    func test두벌식_삭제버튼드래그_동해물고_touchDown선삭제후_전체복구() {
        let sim = HangeulCompositionTestHarness(
            processor: DubeolsikProcessor(automata: automata)
        )

        inputDubeolsik동해물고(into: sim)
        assertTouchDown선삭제후_전체복구(sim, expectedTouchDownText: "동해묽", expectedRestoredText: "동해물고")
    }

    @Test("두벌식 삭제 버튼 드래그 복구: '동해물고' touchDown 후 조합 버퍼의 '물'을 보존")
    func test두벌식_삭제버튼드래그_동해물고_touchDown후_물누락방지() {
        let sim = HangeulCompositionTestHarness(
            processor: DubeolsikProcessor(automata: automata)
        )

        sim.setDeleteDragStateForTesting(
            committed: "동해",
            composing: "물ㄱ",
            deletedCharacters: ["고"]
        )

        while !sim.text.isEmpty {
            sim.dragDeleteLeft()
        }
        #expect(sim.text == "")

        for _ in "동해물고" {
            sim.dragRestoreRight()
        }
        #expect(sim.text == "동해물고", "touchDown으로 삭제된 '고'가 있어도 조합 버퍼의 '물'은 복구 대상에 포함되어야 합니다.")
    }

    @Test("두벌식 삭제 버튼 드래그 복구: '동해물과' touchDown으로 생긴 '동해물고' 전체 복구")
    func test두벌식_삭제버튼드래그_동해물과_touchDown후_동해물고_전체복구() {
        let sim = HangeulCompositionTestHarness(
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
        let sim = HangeulCompositionTestHarness(
            processor: DubeolsikProcessor(automata: automata)
        )

        inputDubeolsik동해물거ㅓ(into: sim)
        assertTouchDown선삭제후_전체복구(sim, expectedTouchDownText: "동해물거", expectedRestoredText: "동해물거ㅓ")
    }

    @Test("천지인 삭제 버튼 드래그 복구: touchDown 선삭제 후 pan 복구가 중복되지 않음")
    func test천지인_삭제버튼드래그_touchDown선삭제후_복구중복방지() {
        let sim = HangeulCompositionTestHarness(
            processor: CheonjiinProcessor(automata: automata)
        )

        inputCheonjiin동해물과(into: sim)
        assertTouchDown선삭제후_복구중복방지(sim)
    }

    @Test("나랏글 삭제 버튼 드래그 복구: touchDown 선삭제 후 pan 복구가 중복되지 않음")
    func test나랏글_삭제버튼드래그_touchDown선삭제후_복구중복방지() {
        let sim = HangeulCompositionTestHarness(
            processor: NaratgeulProcessor(automata: automata)
        )

        inputNaratgeul동해물과(into: sim)
        assertTouchDown선삭제후_복구중복방지(sim)
    }
}

// MARK: - Assertions

private extension HangeulDeleteButtonDragControllerTests {

    func assert전체복구후_버퍼동기화(_ sim: HangeulCompositionTestHarness) {
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

    func assertTouchDown선삭제후_복구중복방지(_ sim: HangeulCompositionTestHarness) {
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
        _ sim: HangeulCompositionTestHarness,
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

private extension HangeulDeleteButtonDragControllerTests {

    func inputDubeolsik동해물과(into sim: HangeulCompositionTestHarness) {
        ["ㄷ", "ㅗ", "ㅇ", "ㅎ", "ㅐ", "ㅁ", "ㅜ", "ㄹ", "ㄱ", "ㅗ", "ㅏ"].forEach {
            sim.input($0)
        }
    }

    func inputDubeolsik동해물고(into sim: HangeulCompositionTestHarness) {
        ["ㄷ", "ㅗ", "ㅇ", "ㅎ", "ㅐ", "ㅁ", "ㅜ", "ㄹ", "ㄱ", "ㅗ"].forEach {
            sim.input($0)
        }
    }

    func inputDubeolsik동해물거ㅓ(into sim: HangeulCompositionTestHarness) {
        ["ㄷ", "ㅗ", "ㅇ", "ㅎ", "ㅐ", "ㅁ", "ㅜ", "ㄹ", "ㄱ", "ㅓ", "ㅓ"].forEach {
            sim.input($0)
        }
    }

    func inputCheonjiin동해물과(into sim: HangeulCompositionTestHarness) {
        [
            "ㄷ", 천, 지, "ㅇ",             // 동
            "ㅅ", "ㅅ", 인, 천, 인,        // 해
            "ㅇ", "ㅇ", 지, 천, "ㄴ", "ㄴ", // 물
            "ㄱ", 천, 지, 인, 천          // 과
        ].forEach {
            sim.input($0)
        }
    }

    func inputNaratgeul동해물과(into sim: HangeulCompositionTestHarness) {
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
