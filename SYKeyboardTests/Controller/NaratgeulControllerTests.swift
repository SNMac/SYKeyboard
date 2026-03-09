//
//  NaratgeulControllerTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 3/8/26.
//

import Testing

@testable import HangeulKeyboardCore

@Suite("나랏글 컨트롤러 통합 검증")
struct NaratgeulControllerTests {
    
    // MARK: - Properties
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    // MARK: - 1. 반복 입력 후 다음 입력과 조합
    
    @Test("반복 입력 후 조합: 'ㄱㄱㄱ' 후 'ㅏ' -> 'ㄱㄱ가'")
    func test반복입력후_조합() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: NaratgeulProcessor(automata: automata)
        )
        
        sim.input("ㄱ")
        sim.repeatInsert("ㄱ")
        sim.repeatInsert("ㄱ")
        #expect(sim.text == "ㄱㄱㄱ")
        
        sim.input("ㅏ")
        #expect(sim.text == "ㄱㄱ가", "반복 입력 후 마지막 자음이 다음 모음과 결합되어야 합니다.")
    }
    
    @Test("반복 입력 후 조합: 'ㅏㅏㅏ' 후 'ㄴ' -> 'ㅏㅏㅏㄴ'")
    func test반복입력_모음후_자음() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: NaratgeulProcessor(automata: automata)
        )
        
        sim.input("ㅏ")
        sim.repeatInsert("ㅏ")
        sim.repeatInsert("ㅏ")
        #expect(sim.text == "ㅏㅏㅏ")
        
        sim.input("ㄴ")
        #expect(sim.text == "ㅏㅏㅏㄴ")
    }
    
    // MARK: - 2. 반복 삭제 후 끌어오기
    
    @Test("반복 삭제 후 조합: 'ㄱㄱㄱㅏㅏ' -> 반복 삭제 -> 'ㄱ' -> 'ㅏ' -> '가'")
    func test반복삭제후_끌어오기_조합() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: NaratgeulProcessor(automata: automata)
        )
        
        sim.input("ㄱ")
        sim.repeatInsert("ㄱ")
        sim.repeatInsert("ㄱ")
        sim.repeatInsert("ㅏ")
        sim.repeatInsert("ㅏ")
        #expect(sim.text == "ㄱㄱㄱㅏㅏ")
        
        // 반복 삭제로 'ㄱ'까지
        sim.repeatDelete() // ㄱㄱㄱㅏ
        sim.repeatDelete() // ㄱㄱㄱ
        sim.repeatDelete() // ㄱㄱ
        sim.repeatDelete() // ㄱ
        sim.finishRepeatDelete() // 끌어오기 → composing = "ㄱ"
        
        sim.input("ㅏ")
        #expect(sim.text == "가", "반복 삭제 후 끌어오기 된 글자와 다음 입력이 조합되어야 합니다.")
    }
    
    // MARK: - 3. 반복 입력 후 획추가/쌍자음
    
    @Test("반복 입력 후 획추가: 'ㄱㄱㄱ' 후 '획' -> 'ㄱㄱㅋ'")
    func test반복입력후_획추가() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: NaratgeulProcessor(automata: automata)
        )
        
        sim.input("ㄱ")
        sim.repeatInsert("ㄱ")
        sim.repeatInsert("ㄱ")
        #expect(sim.text == "ㄱㄱㄱ")
        
        sim.input("획")
        #expect(sim.text == "ㄱㄱㅋ", "반복 입력 후 마지막 글자에 획추가가 적용되어야 합니다.")
    }
}
