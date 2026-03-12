//
//  CheonjiinControllerTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 3/8/26.
//

import Testing

@testable import HangeulKeyboardCore

@Suite("천지인 컨트롤러 통합 검증")
struct CheonjiinControllerTests {
    
    // MARK: - Properties
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    private let 천 = "ㆍ"
    private let 지 = "ㅡ"
    private let 인 = "ㅣ"
    
    // MARK: - 1. 확정 후 삭제 종성 합치기 방지
    
    @Test("확정 후 삭제: '가(확정)나' -> 삭제 -> '가ㄴ'")
    func test확정후_삭제_종성합치기방지() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        sim.input("ㄱ"); sim.input(인); sim.input(천) // 가
        sim.space()
        sim.input("ㄴ"); sim.input(인); sim.input(천) // 나
        #expect(sim.text == "가나")
        
        sim.delete()
        #expect(sim.text == "가ㄴ", "확정된 글자에는 종성이 합쳐지면 안 됩니다.")
    }
    
    @Test("확정 후 연속 삭제: '가(확정)나다' -> 전체 삭제")
    func test확정후_연속삭제() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        sim.input("ㄱ"); sim.input(인); sim.input(천) // 가
        sim.space()
        sim.input("ㄴ"); sim.input(인); sim.input(천) // 나
        sim.input("ㄷ"); sim.input(인); sim.input(천) // 다
        #expect(sim.text == "가나다")
        
        sim.delete() // 가낟
        sim.delete() // 가나
        sim.delete() // 가ㄴ
        #expect(sim.text == "가ㄴ", "확정 경계를 넘어 종성이 합쳐지면 안 됩니다.")
        
        sim.delete() // 가
        #expect(sim.text == "가")
        
        sim.delete() // ㄱ
        #expect(sim.text == "ㄱ")
        
        sim.delete() // ""
        #expect(sim.text == "")
    }
    
    // MARK: - 2. 확정 후 삭제 -> 재입력 조합 방지
    
    @Test("확정 후 삭제 -> 재입력: '가(확정)ㄴ' -> 삭제 -> '가' -> 'ㄴ' -> '가ㄴ'")
    func test확정후_삭제_재입력() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        sim.input("ㄱ"); sim.input(인); sim.input(천) // 가
        sim.space()
        sim.input("ㄴ") // 가ㄴ
        
        sim.delete() // 가
        #expect(sim.text == "가")
        
        sim.input("ㄴ")
        #expect(sim.text == "가ㄴ", "확정된 글자와 조합되면 안 됩니다.")
    }
    
    // MARK: - 3. 반복 삭제 후 확정 보호 유지
    
    @Test("반복 삭제 후 확정 보호: '가(확정)니ㅣㅣ' -> 반복 삭제 -> '가니' -> 삭제 -> '가ㄴ'")
    func test반복삭제후_확정보호() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        sim.input("ㄱ"); sim.input(인); sim.input(천) // 가
        sim.space()
        sim.input("ㄴ"); sim.input(인) // 니
        
        // ㅣ 반복 입력으로 니ㅣㅣ 만들기
        sim.repeatInsert("ㅣ") // 니 commit + ㅣ
        sim.repeatInsert("ㅣ") // ㅣ commit + ㅣ
        #expect(sim.text == "가니ㅣㅣ")
        
        // 반복 삭제로 가니까지
        sim.repeatDelete() // 가니ㅣ
        sim.repeatDelete() // 가니
        sim.finishRepeatDelete() // 끌어오기
        
        // 일반 삭제
        sim.delete() // 가ㄴ
        #expect(sim.text == "가ㄴ", "반복 삭제 후에도 확정 보호가 유지되어야 합니다.")
    }
    
    @Test("반복 삭제로 확정 글자까지 도달: '가(확정)니ㅣㅣ' -> 반복 삭제 -> '가' -> 'ㄴ' -> '가ㄴ'")
    func test반복삭제_확정글자까지() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        sim.input("ㄱ"); sim.input(인); sim.input(천) // 가
        sim.space()
        sim.input("ㄴ"); sim.input(인) // 니
        
        sim.repeatInsert("ㅣ")
        sim.repeatInsert("ㅣ")
        
        // 반복 삭제로 가까지
        sim.repeatDelete() // 가니ㅣ
        sim.repeatDelete() // 가니
        sim.repeatDelete() // 가
        sim.finishRepeatDelete() // 끌어오기
        
        sim.input("ㄴ")
        #expect(sim.text == "가ㄴ", "확정된 글자와 조합되면 안 됩니다.")
    }
    
    // MARK: - 4. 반복 입력 모음 조합 (ㅏㅏㅏ + ㆍ 길게 → ㅏㅏㅑㅑㅑ)
    
    @Test("반복 입력 모음 조합: 'ㅏㅏㅏ' 후 'ㆍ' 길게 -> 'ㅏㅏㅑㅑㅑ'")
    func test반복입력_모음조합() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        // ㅣ 입력 후 ㆍ 길게 눌러 ㅏㅏㅏ 만들기
        sim.input(인) // ㅣ
        sim.repeatStart(천) // ㅣ + ㆍ = ㅏ (repeat 시작 시 조합)
        sim.repeatInsert("ㅏ") // ㅏ commit + ㅏ
        sim.repeatInsert("ㅏ") // ㅏ commit + ㅏ
        #expect(sim.text == "ㅏㅏㅏ")
        
        // 손 뗀 후 다시 ㆍ 길게 → 마지막 ㅏ가 ㅑ로 교체
        sim.repeatStart(천) // ㅏ + ㆍ = ㅑ
        #expect(sim.text == "ㅏㅏㅑ")
        
        sim.repeatInsert("ㅑ")
        sim.repeatInsert("ㅑ")
        #expect(sim.text == "ㅏㅏㅑㅑㅑ")
    }
    
    // MARK: - 5. 반복 입력 후 다음 입력과 조합
    
    @Test("반복 입력 후 조합: 'ㄱㄱㄱ' 길게 후 'ㅣ' -> 'ㄱㄱ기'")
    func test반복입력후_조합() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        // ㄱ 처음부터 길게 → ㄱㄱㄱ
        sim.input("ㄱ") // 첫 입력
        sim.repeatInsert("ㄱ")
        sim.repeatInsert("ㄱ")
        #expect(sim.text == "ㄱㄱㄱ")
        
        // ㅣ 입력 → 마지막 ㄱ과 조합
        sim.input(인)
        #expect(sim.text == "ㄱㄱ기", "반복 입력 후 마지막 글자가 다음 입력과 조합되어야 합니다.")
    }
    
    // MARK: - 6. 확정 보호 해제 후 종성 복원
    
    @Test("확정 보호 해제 후 종성 복원: '가나(확정)다' -> 삭제 3번 -> 재입력 '나니' -> 삭제 -> '가난'")
    func test확정보호해제후_종성복원() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        // 1. '가나' 입력 후 확정
        sim.input("ㄱ"); sim.input(인); sim.input(천) // 가
        sim.input("ㄴ"); sim.input(인); sim.input(천) // 나
        sim.space()
        
        // 2. '다' 입력
        sim.input("ㄷ"); sim.input(인); sim.input(천) // 다
        #expect(sim.text == "가나다")
        
        // 3. 삭제 3번 -> '가ㄴ' (확정 영역 진입)
        sim.delete() // 가나ㄷ
        sim.delete() // 가나
        sim.delete() // 가ㄴ
        #expect(sim.text == "가ㄴ")
        
        // 4. 재입력 '나니' (ㅣㆍㄴㅣ)
        sim.input(인); sim.input(천) // 가나
        sim.input("ㄴ"); sim.input(인) // 가나니
        #expect(sim.text == "가나니")
        
        // 5. 삭제 -> '가난' (보호 해제되었으므로 종성 복원 동작)
        sim.delete()
        #expect(sim.text == "가난", "확정 영역이 삭제로 해제된 후에는 종성 복원이 동작해야 합니다.")
    }
    
    @Test("확정 직후 삭제: '가나(확정)다' -> 삭제 1번 -> '가나ㄷ' (보호 유지)")
    func test확정직후_삭제_보호유지() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        sim.input("ㄱ"); sim.input(인); sim.input(천) // 가
        sim.input("ㄴ"); sim.input(인); sim.input(천) // 나
        sim.space()
        sim.input("ㄷ"); sim.input(인); sim.input(천) // 다
        #expect(sim.text == "가나다")
        
        sim.delete()
        #expect(sim.text == "가나ㄷ", "확정 영역이 손상되지 않았으므로 종성 합치기가 방지되어야 합니다.")
    }
    
    @Test("확정 직후 삭제 -> 재입력: '가나(확정)' -> 삭제 2번 -> 'ㄷ' 입력 -> '가나ㄷ' (보호 유지)")
    func test확정후_삭제2번_재입력_보호유지() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        sim.input("ㄱ"); sim.input(인); sim.input(천) // 가
        sim.input("ㄴ"); sim.input(인); sim.input(천) // 나
        sim.space()
        sim.input("ㄷ"); sim.input(인); sim.input(천) // 다
        
        // 삭제 2번으로 '가나'까지 돌림 (확정 글자 '나'를 끌어옴, 아직 분해하지 않음)
        sim.delete() // 가나ㄷ
        sim.delete() // 가나
        
        // 'ㄷ' 입력 -> 보호된 '나'와 합쳐지면 안 됨
        sim.input("ㄷ")
        #expect(sim.text == "가나ㄷ", "끌어온 보호 글자에 새 자음이 결합되면 안 됩니다.")
    }
    
    @Test("확정 보호 해제 경계: '가(확정)나' -> 삭제로 'ㄴ'까지 -> 재입력 -> 종성 복원")
    func test확정보호해제_경계() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        // '가' 확정
        sim.input("ㄱ"); sim.input(인); sim.input(천)
        sim.space()
        
        // '나' 입력 후 전부 삭제해서 'ㄴ'까지
        sim.input("ㄴ"); sim.input(인); sim.input(천) // 나
        sim.delete() // ㄴ -> 확정 '가'와 합쳐지면 안 됨
        #expect(sim.text == "가ㄴ", "확정 영역이 유지되어 종성 합치기가 방지되어야 합니다.")
        
        // 삭제해서 '가'만 남기고 확정 글자 진입
        sim.delete() // 가
        sim.delete() // ㄱ (확정 영역 분해 -> 보호 해제)
        
        // 재입력 '가나니'
        sim.input(인); sim.input(천) // 가
        sim.input("ㄴ"); sim.input(인); sim.input(천) // 나
        sim.input("ㄴ"); sim.input(인) // 니
        #expect(sim.text == "가나니")
        
        // 삭제 -> '가난' (보호 해제되었으므로 종성 복원 동작)
        sim.delete()
        #expect(sim.text == "가난", "확정 영역 분해 후에는 종성 복원이 동작해야 합니다.")
    }
    
    // MARK: - 7. 확정 보호 유지: 끌어오기 후 재입력
    
    @Test("확정 보호 유지: '가(확정)나' -> 삭제 2번 -> '가' -> '나' 입력 -> 삭제 -> '가ㄴ'")
    func test확정보호_끌어오기후_재입력() {
        let sim = KeyboardControllerSimulator(
            automata: automata,
            processor: CheonjiinProcessor(automata: automata)
        )
        
        // 1. '가' 확정
        sim.input("ㄱ"); sim.input(인); sim.input(천)
        sim.space()
        
        // 2. '나' 입력
        sim.input("ㄴ"); sim.input(인); sim.input(천)
        #expect(sim.text == "가나")
        
        // 3. 삭제 2번 -> '가' (보호된 글자 끌어오기)
        sim.delete() // 가ㄴ
        sim.delete() // 가
        #expect(sim.text == "가")
        
        // 4. '나' 다시 입력
        sim.input("ㄴ"); sim.input(인); sim.input(천)
        #expect(sim.text == "가나")
        
        // 5. 삭제 -> '가ㄴ' (확정 보호 유지)
        sim.delete()
        #expect(sim.text == "가ㄴ", "끌어온 보호 글자가 committed로 돌아갈 때 보호 상태가 유지되어야 합니다.")
    }
}
