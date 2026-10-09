//
//  NaratgeulCompositionScenarioTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 3/8/26.
//

import Testing

@testable import HangeulKeyboardCore

@Suite("나랏글 HangeulCompositionState 기반 입력 상태 시나리오")
struct NaratgeulCompositionScenarioTests {
    
    // MARK: - Properties
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    // MARK: - 1. 반복 입력 후 다음 입력과 조합·획추가
    
    @Test("반복 입력 뒤 다음 키는 마지막 글자와만 조합·획추가되고 앞 글자는 그대로 남음",
          arguments: [
            // (label, firstKey, nextKey, expectedAfterRepeat, expectedFinal)
            ("반복 입력 후 조합: 'ㄱㄱㄱ' 후 'ㅏ' -> 'ㄱㄱ가' (마지막 자음이 다음 모음과 결합)",
             "ㄱ", "ㅏ", "ㄱㄱㄱ", "ㄱㄱ가"),
            ("반복 입력 후 조합: 'ㅏㅏㅏ' 후 'ㄴ' -> 'ㅏㅏㅏㄴ'",
             "ㅏ", "ㄴ", "ㅏㅏㅏ", "ㅏㅏㅏㄴ"),
            ("반복 입력 후 획추가: 'ㄱㄱㄱ' 후 '획' -> 'ㄱㄱㅋ' (마지막 글자에 획추가 적용)",
             "ㄱ", "획", "ㄱㄱㄱ", "ㄱㄱㅋ")
          ])
    func test반복입력후_다음입력(
        label: String,
        firstKey: String,
        nextKey: String,
        expectedAfterRepeat: String,
        expectedFinal: String
    ) {
        let sim = HangeulCompositionTestHarness(
            processor: NaratgeulProcessor(automata: automata)
        )
        
        sim.input(firstKey)
        sim.repeatInsert()
        sim.repeatInsert()
        #expect(sim.text == expectedAfterRepeat, "\(label)")
        
        sim.input(nextKey)
        #expect(sim.text == expectedFinal, "\(label)")
    }
    
    // MARK: - 2. 반복 삭제 후 끌어오기
    
    @Test("반복 삭제 후 조합: 'ㄱㄱ가ㅏ' -> 반복 삭제 -> 'ㄱ' -> 'ㅏ' -> '가'")
    func test반복삭제후_끌어오기_조합() {
        let sim = HangeulCompositionTestHarness(
            processor: NaratgeulProcessor(automata: automata)
        )
        
        sim.input("ㄱ")
        sim.repeatInsert()
        sim.repeatInsert()
        sim.input("ㅏ")   // ㄱㄱ가
        sim.repeatInsert() // ㄱㄱ가ㅏ
        #expect(sim.text == "ㄱㄱ가ㅏ")
        
        // 반복 삭제로 'ㄱ'까지
        sim.repeatDelete() // ㄱㄱ가
        sim.repeatDelete() // ㄱㄱ
        sim.repeatDelete() // ㄱ
        sim.finishRepeatDelete() // 끌어오기 → composing = "ㄱ"
        
        sim.input("ㅏ")
        #expect(sim.text == "가", "반복 삭제 후 끌어오기 된 글자와 다음 입력이 조합되어야 합니다.")
    }
    
}
