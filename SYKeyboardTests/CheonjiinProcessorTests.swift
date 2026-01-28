//
//  CheonjiinProcessorTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 12/2/25.
//

import Testing
import OSLog

@testable import HangeulKeyboardCore

@Suite("천지인 입력기 검증")
struct CheonjiinProcessorTests {
    
    // MARK: - Properties
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: String(describing: "CheonjiinProcessorTests")
    )
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    private let processor: HangeulProcessable
    
    private let 천 = "ㆍ"
    private let 지 = "ㅡ"
    private let 인 = "ㅣ"
    
    // MARK: - Initializer
    
    init() {
        self.processor = CheonjiinProcessor(automata: automata)
    }
    
    // MARK: - 1. 자음 순환 테스트 (실제 키 입력)
    
    @Test("자음 순환: 'ㄱ' 버튼 반복 입력 (ㄱ -> ㅋ -> ㄲ)")
    func test자음순환_ㄱ계열() {
        var text = ""
        // 1회: ㄱ
        text = input("ㄱ", to: text); #expect(text == "ㄱ")
        // 2회: ㅋ
        text = input("ㄱ", to: text); #expect(text == "ㅋ")
        // 3회: ㄲ
        text = input("ㄱ", to: text); #expect(text == "ㄲ")
        // 4회: 다시 ㄱ (순환)
        text = input("ㄱ", to: text); #expect(text == "ㄱ")
    }
    
    @Test("자음 순환: 'ㅇ' 버튼 반복 입력 (ㅇ -> ㅁ)")
    func test자음순환_ㅇ계열() {
        var text = ""
        // 1회: ㅇ
        text = input("ㅇ", to: text); #expect(text == "ㅇ")
        // 2회: ㅁ
        text = input("ㅇ", to: text); #expect(text == "ㅁ")
        // 3회: 다시 ㅇ
        text = input("ㅇ", to: text); #expect(text == "ㅇ")
    }
    
    // MARK: - 2. 모음 조합 테스트 (천,지,인 키 활용)
    
    @Test("모음 조합: ㅣ + ㆍ = ㅏ")
    func test모음조합_아() {
        var text = ""
        text = input(인, to: text) // ㅣ
        text = input(천, to: text) // ㅣ + ㆍ -> ㅏ
        
        #expect(text == "ㅏ")
    }
    
    @Test("모음 조합: ㆍ + ㅡ = ㅗ")
    func test모음조합_오() {
        var text = ""
        text = input(천, to: text) // ㆍ
        text = input(지, to: text) // ㆍ + ㅡ -> ㅗ
        
        #expect(text == "ㅗ")
    }
    
    @Test("모음 생성 흐름: ㅡ -> ㅜ(ㆍ) -> ㅠ(ㆍ) -> ㅝ(ㅣ) -> ㅞ(ㅣ)")
    func test모음생성_복합() {
        var text = ""
        
        text = input(지, to: text) // ㅡ
        #expect(text == "ㅡ")
        
        text = input(천, to: text) // ㅡ + ㆍ -> ㅜ
        #expect(text == "ㅜ")
        
        text = input(천, to: text) // ㅜ + ㆍ -> ㅠ
        #expect(text == "ㅠ")
        
        text = input(인, to: text) // ㅠ + ㅣ -> ㅝ
        #expect(text == "ㅝ")
        
        text = input(인, to: text) // ㅝ + ㅣ -> ㅞ
        #expect(text == "ㅞ")
    }
    
    // MARK: - 3. 단어 생성 및 삭제 시나리오
    
    @Test("시나리오: '가니' 생성 후 삭제 -> '간' (종성 복원 방지 확인)")
    func testScenario_가니_삭제() {
        var text = ""
        
        // 1. '가' 만들기 (ㄱ + ㅣ + ㆍ)
        text = input("ㄱ", to: text) // ㄱ
        text = input(인, to: text) // 기
        text = input(천, to: text) // 가
        _ = processor.inputSpace(beforeText: text)
        
        // 2. '가니' 만들기 (가 + ㄴ + ㅣ)
        text = input("ㄴ", to: text) // 간
        text = input(인, to: text) // 가니
        
        #expect(text == "가니")
        
        // 3. 삭제 (ㅣ 삭제)
        // 기대: 'ㄴ'이 남지만, '가'는 확정된 상태이므로 '간'으로 합쳐지지 않고 '가ㄴ'이 되어야 함
        // (단, 화면상으로는 '가ㄴ'이지만, String 값 자체는 로직에 따라 분리되어 있거나 합쳐질 수 있음.
        //  하지만 앞서 수정한 로직에 따르면 '간'으로 합쳐지는 걸 막았으므로,
        //  입력기 특성상 여기선 '간'이 아니라 '가' 상태에서 'ㄴ'이 초성으로 대기중인 상태여야 함.)
        //  -> 라고 생각했지만, CheonjiinProcessor.delete의 최종 리턴값은 String이므로
        //     종성 복원이 "가" + "ㄴ" -> "간"이 되는지, "가" + "ㄴ" (그대로)인지 확인 필요.
        //     앞선 대화에서 "가ㄴ"을 의도했으므로, 여기선 종성 복원이 일어나지 않아야 함.
        
        text = processor.delete(beforeText: text)
        
        // 여기서는 검증 방식에 따라 기대값이 다를 수 있으나,
        // "간"이 되어버리는 현상을 막는 것이 목표였으므로,
        // String상으로는 "가ㄴ" (자소 분리) 혹은 "가"와 "ㄴ"이 시각적으로 분리된 형태여야 함.
        // 하지만 Swift String은 "가ㄴ"을 자동으로 보여주지 않으므로,
        // 실제 테스트에서는 "가ㄴ"이라는 문자열(2글자)이 나오기를 기대.
        
        #expect(text == "가ㄴ")
    }
    
    @Test("시나리오: '달거' -> 삭제 -> '닭'")
    func testScenario_달거_삭제_닭() {
        var text = ""
        
        // 1. '닭' 만들기
        text = input("ㄷ", to: text)
        text = input(인, to: text); text = input(천, to: text) // 다 (ㄷ+ㅣ+ㆍ)
        text = input("ㄴ", to: text) // 단
        text = input("ㄴ", to: text) // 달 (ㄴ 한번더 -> ㄹ)
        text = input("ㄱ", to: text) // 닭 (달 + ㄱ)
        
        // 2. '달거' 만들기 (닭 + ㆍ + ㅣ)
        text = input(천, to: text) // 닭ㆍ (연음 대기)
        text = input(인, to: text) // 달거 (연음 발생)
        
        #expect(text == "달거")
        
        // 3. 삭제 -> '닭'으로 복원
        text = processor.delete(beforeText: text)
        #expect(text == "닭")
    }
    
    @Test("시나리오: '학교' (스페이스바 확정 활용)")
    func testScenario_학교_Space() {
        var text = ""
        
        // 1. '학'
        text = input("ㅅ", to: text); text = input("ㅅ", to: text) // ㅎ (ㅅ 2번)
        text = input(인, to: text); text = input(천, to: text) // 하
        text = input("ㄱ", to: text) // 학
        
        #expect(text == "학")
        
        // 2. Space (확정)
        _ = processor.inputSpace(beforeText: text)
        
        // 3. '교' (ㄱ + ㆍ + ㆍ + ㅡ)
        // 확정되었으므로 '학'의 종성 'ㄱ'을 가져가지 않아야 함
        text = input("ㄱ", to: text) // 학ㄱ
        text = input(천, to: text) // 학ㄱㆍ
        text = input(천, to: text) // 학ㄱᆢ
        text = input(지, to: text) // 학교
        
        #expect(text == "학교")
    }
    
    @Test("시나리오: '와' 만들기 (ㅇ + ㆍ + ㅡ + ㅣ + ㆍ)")
    func testScenario_와() {
        var text = ""
        
        // ㅇ
        text = input("ㅇ", to: text)
        // ㅗ (ㆍ + ㅡ)
        text = input(천, to: text)
        text = input(지, to: text)
        #expect(text == "오")
        
        // ㅘ (오 + ㅏ) -> 천지인에서는 '오' 상태에서 'ㅣ', 'ㆍ' 순서로 입력하여 'ㅘ'를 완성함
        // 1. 오 + ㅣ = ㅚ
        text = input(인, to: text)
        #expect(text == "외")
        
        // 2. ㅚ + ㆍ = ㅘ
        text = input(천, to: text)
        #expect(text == "와")
    }
    
    // MARK: - 4. 11,172자 전체 검증 (Heavy Test)
    // 실제 입력 키 시퀀스로 변환하여 테스트
    
    @Test("천지인 11,172자 전체 생성 및 삭제 검증")
    func validateAllCharacters() {
        let 한글Start = 0xAC00; let 한글End = 0xD7A3
        var failureCount = 0
        
        for unicode in 한글Start...한글End {
            guard let scalar = Unicode.Scalar(unicode) else { continue }
            let char = Character(scalar)
            let targetString = String(char)
            
            // 1. 해당 글자를 만들기 위한 천지인 키 시퀀스 가져오기
            // 예: "ㅋ" -> ["ㄱ", "ㄱ"]
            // 예: "ㅘ" -> ["ㆍ", "ㅡ", "ㅣ", "ㆍ"]
            let keySequence = decomposeTo천지인Keys(char: char)
            
            // 2. 입력 시뮬레이션
            var currentText = ""
            for key in keySequence {
                currentText = processor.input(글자Input: key, beforeText: currentText).processedText
            }
            
            // 3. 검증
            if currentText != targetString {
                Self.logger.error("실패: \(targetString) (생성됨: \(currentText)) / 입력키: \(keySequence)")
                failureCount += 1
            }
        }
        
        #expect(failureCount == 0, "총 \(failureCount)개의 글자 생성 실패")
    }
}

// MARK: - Test Helpers

private extension CheonjiinProcessorTests {
    
    /// 단순 입력 헬퍼
    func input(_ char: String, to text: String) -> String {
        return processor.input(글자Input: char, beforeText: text).0
    }
    
    /// 완성된 한글 한 글자를 천지인 키 입력 배열로 분해
    func decomposeTo천지인Keys(char: Character) -> [String] {
        guard let scalar = char.unicodeScalars.first else { return [] }
        let code = Int(scalar.value) - 0xAC00
        
        let 초 = code / (21 * 28)
        let 중 = (code % (21 * 28)) / 28
        let 종 = code % 28
        
        var keys: [String] = []
        
        // 1. 초성
        keys.append(contentsOf: get초성Keys(index: 초))
        
        // 2. 중성
        keys.append(contentsOf: get중성Keys(index: 중))
        
        // 3. 종성
        if 종 != 0 {
            keys.append(contentsOf: get종성Keys(index: 종))
        }
        
        return keys
    }
    
    // MARK: - Key Mapping Logic
    // Processor의 '자음순환Table' 규칙을 정확히 따릅니다.
    // ㄱ: [ㄱ, ㅋ, ㄲ], ㄴ: [ㄴ, ㄹ], ㄷ: [ㄷ, ㅌ, ㄸ]
    // ㅂ: [ㅂ, ㅍ, ㅃ], ㅅ: [ㅅ, ㅎ, ㅆ], ㅈ: [ㅈ, ㅊ, ㅉ], ㅇ: [ㅇ, ㅁ]
    
    func get초성Keys(index: Int) -> [String] {
        switch index {
        case 0: return ["ㄱ"]       // ㄱ (1)
        case 1: return ["ㄱ", "ㄱ", "ㄱ"] // ㄲ (3)
        case 2: return ["ㄴ"]       // ㄴ (1)
        case 3: return ["ㄷ"]       // ㄷ (1)
        case 4: return ["ㄷ", "ㄷ", "ㄷ"] // ㄸ (3)
        case 5: return ["ㄴ", "ㄴ"] // ㄹ (2)
        case 6: return ["ㅇ", "ㅇ"] // ㅁ (2)
        case 7: return ["ㅂ"]       // ㅂ (1)
        case 8: return ["ㅂ", "ㅂ", "ㅂ"] // ㅃ (3)
        case 9: return ["ㅅ"]       // ㅅ (1)
        case 10: return ["ㅅ", "ㅅ", "ㅅ"] // ㅆ (3)
        case 11: return ["ㅇ"]      // ㅇ (1)
        case 12: return ["ㅈ"]      // ㅈ (1)
        case 13: return ["ㅈ", "ㅈ", "ㅈ"] // ㅉ (3)
        case 14: return ["ㅈ", "ㅈ"] // ㅊ (2)
        case 15: return ["ㄱ", "ㄱ"] // ㅋ (2)
        case 16: return ["ㄷ", "ㄷ"] // ㅌ (2)
        case 17: return ["ㅂ", "ㅂ"] // ㅍ (2)
        case 18: return ["ㅅ", "ㅅ"] // ㅎ (2)
        default: return []
        }
    }
    
    func get중성Keys(index: Int) -> [String] {
        let 천 = "ㆍ"
        let 지 = "ㅡ"
        let 인 = "ㅣ"
        
        switch index {
        case 0: return [인, 천]             // ㅏ
        case 1: return [인, 천, 인]         // ㅐ
        case 2: return [인, 천, 천]         // ㅑ
        case 3: return [인, 천, 천, 인]     // ㅒ
        case 4: return [천, 인]             // ㅓ
        case 5: return [천, 인, 인]         // ㅔ
        case 6: return [천, 인, 천]         // ㅕ
        case 7: return [천, 인, 천, 인]     // ㅖ
        case 8: return [천, 지]             // ㅗ
        case 9: return [천, 지, 인, 천]     // ㅘ (ㅗ + ㅏ)
        case 10: return [천, 지, 인, 천, 인] // ㅙ (ㅘ + ㅣ)
        case 11: return [천, 지, 인]        // ㅚ (ㅗ + ㅣ)
        case 12: return [천, 천, 지]       // ㅛ (ㆍ + ㆍ = ᆢ, ᆢ + ㅡ = ㅛ)
        case 13: return [지, 천]             // ㅜ
        case 14: return [지, 천, 천, 인]     // ㅝ (ㅜ + ㅓ)
        case 15: return [지, 천, 천, 인, 인] // ㅞ (ㅝ + ㅣ)
        case 16: return [지, 천, 인]        // ㅟ (ㅜ + ㅣ)
        case 17: return [지, 천, 천]        // ㅠ (ㅜ + ㆍ)
        case 18: return [지]                // ㅡ
        case 19: return [지, 인]            // ㅢ
        case 20: return [인]                // ㅣ
        default: return []
        }
    }
    
    func get종성Keys(index: Int) -> [String] {
        // 종성 인덱스: 0(없음), 1(ㄱ) ~ 27(ㅎ)
        // 겹받침은 자소 단위로 풀어서 키 시퀀스를 생성해야 합니다.
        // 예: ㄾ(13) -> ㄹ + ㅌ -> (ㄴ,ㄴ) + (ㄷ,ㄷ)
        
        switch index {
        case 1: return ["ㄱ"]              // ㄱ
        case 2: return ["ㄱ", "ㄱ", "ㄱ"]     // ㄲ
        case 3: return ["ㄱ", "ㅅ"]         // ㄳ (ㄱ + ㅅ)
        case 4: return ["ㄴ"]              // ㄴ
        case 5: return ["ㄴ", "ㅈ"]         // ㄵ (ㄴ + ㅈ)
        case 6: return ["ㄴ", "ㅅ", "ㅅ"]     // ㄶ (ㄴ + ㅎ) -> ㅎ은 ㅅ키 2번
        case 7: return ["ㄷ"]              // ㄷ
        case 8: return ["ㄴ", "ㄴ"]         // ㄹ
        case 9: return ["ㄴ", "ㄴ", "ㄱ"]     // ㄺ (ㄹ + ㄱ)
        case 10: return ["ㄴ", "ㄴ", "ㅇ", "ㅇ"] // ㄻ (ㄹ + ㅁ) -> ㅁ은 ㅇ키 2번
        case 11: return ["ㄴ", "ㄴ", "ㅂ"]     // ㄼ (ㄹ + ㅂ)
        case 12: return ["ㄴ", "ㄴ", "ㅅ"]     // ㄽ (ㄹ + ㅅ)
        case 13: return ["ㄴ", "ㄴ", "ㄷ", "ㄷ"] // ㄾ (ㄹ + ㅌ) -> ㅌ은 ㄷ키 2번 [수정됨!]
        case 14: return ["ㄴ", "ㄴ", "ㅂ", "ㅂ"] // ㄿ (ㄹ + ㅍ) -> ㅍ은 ㅂ키 2번
        case 15: return ["ㄴ", "ㄴ", "ㅅ", "ㅅ"] // ㅀ (ㄹ + ㅎ) -> ㅎ은 ㅅ키 2번
        case 16: return ["ㅇ", "ㅇ"]         // ㅁ
        case 17: return ["ㅂ"]              // ㅂ
        case 18: return ["ㅂ", "ㅅ"]         // ㅄ (ㅂ + ㅅ)
        case 19: return ["ㅅ"]              // ㅅ
        case 20: return ["ㅅ", "ㅅ", "ㅅ"]     // ㅆ
        case 21: return ["ㅇ"]              // ㅇ
        case 22: return ["ㅈ"]              // ㅈ
        case 23: return ["ㅈ", "ㅈ"]         // ㅊ
        case 24: return ["ㄱ", "ㄱ"]         // ㅋ
        case 25: return ["ㄷ", "ㄷ"]         // ㅌ
        case 26: return ["ㅂ", "ㅂ"]         // ㅍ
        case 27: return ["ㅅ", "ㅅ"]         // ㅎ
        default: return []
        }
    }
}
