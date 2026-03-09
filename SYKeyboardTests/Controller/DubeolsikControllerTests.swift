//
//  DubeolsikControllerTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 3/8/26.
//

import Testing

@testable import HangeulKeyboardCore

@Suite("두벌식 컨트롤러 통합 검증")
struct DubeolsikControllerTests {
    
    // MARK: - Properties
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    // MARK: - 1. 반복 입력 후 다음 입력과 조합
    
    @Test("반복 입력 후 조합: 'ㄱㄱㄱ' 후 'ㅣ' -> 'ㄱㄱ기'")
    func test반복입력후_조합() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: DubeolsikProcessor(automata: automata)
        )
        
        sim.input("ㄱ")
        sim.repeatInsert("ㄱ")
        sim.repeatInsert("ㄱ")
        #expect(sim.text == "ㄱㄱㄱ")
        
        sim.input("ㅣ")
        #expect(sim.text == "ㄱㄱ기", "반복 입력 후 마지막 글자가 다음 입력과 조합되어야 합니다.")
    }
    
    @Test("반복 입력 후 조합: 'ㅏㅏㅏ' 후 'ㄴ' -> 'ㅏㅏㅏㄴ'")
    func test반복입력_모음후_자음() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: DubeolsikProcessor(automata: automata)
        )
        
        sim.input("ㅏ")
        sim.repeatInsert("ㅏ")
        sim.repeatInsert("ㅏ")
        #expect(sim.text == "ㅏㅏㅏ")
        
        sim.input("ㄴ")
        #expect(sim.text == "ㅏㅏㅏㄴ")
    }
    
    // MARK: - 2. 반복 삭제 후 끌어오기
    
    @Test("반복 삭제 후 조합: '개ㅐㅐㅏㅏ' -> 반복 삭제 -> '개' -> 'ㄴ' -> '갠'")
    func test반복삭제후_끌어오기_조합() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: DubeolsikProcessor(automata: automata)
        )
        
        // '개' 입력
        sim.input("ㄱ"); sim.input("ㅐ") // 개
        
        // ㅐ 반복 입력
        sim.repeatInsert("ㅐ")
        sim.repeatInsert("ㅏ")
        sim.repeatInsert("ㅏ")
        #expect(sim.text == "개ㅐㅏㅏ")
        
        // 반복 삭제로 '개'까지
        sim.repeatDelete() // 개ㅐㅏ
        sim.repeatDelete() // 개ㅐ
        sim.repeatDelete() // 개
        sim.finishRepeatDelete() // 끌어오기 → composing = "개"
        
        sim.input("ㄴ")
        #expect(sim.text == "갠", "반복 삭제 후 끌어오기 된 글자와 다음 입력이 조합되어야 합니다.")
    }
    
    // MARK: - 3. 반복 입력 후 연음
    
    @Test("반복 입력 후 연음: 'ㄱㄱㄱ' 후 'ㅏ' -> 'ㄱㄱ가'")
    func test반복입력후_연음() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: DubeolsikProcessor(automata: automata)
        )
        
        sim.input("ㄱ")
        sim.repeatInsert("ㄱ")
        sim.repeatInsert("ㄱ")
        #expect(sim.text == "ㄱㄱㄱ")
        
        sim.input("ㅏ")
        #expect(sim.text == "ㄱㄱ가", "반복 입력 후 마지막 자음이 다음 모음과 결합되어야 합니다.")
    }
}
