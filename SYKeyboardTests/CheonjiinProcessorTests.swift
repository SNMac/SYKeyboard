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
        var (c, p) = ("", "")
        (c, p) = applyInput("ㄱ", committed: c, composing: p); #expect(c + p == "ㄱ")
        (c, p) = applyInput("ㄱ", committed: c, composing: p); #expect(c + p == "ㅋ")
        (c, p) = applyInput("ㄱ", committed: c, composing: p); #expect(c + p == "ㄲ")
        (c, p) = applyInput("ㄱ", committed: c, composing: p); #expect(c + p == "ㄱ")
    }
    
    @Test("자음 순환: 'ㅇ' 버튼 반복 입력 (ㅇ -> ㅁ)")
    func test자음순환_ㅇ계열() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㅇ", committed: c, composing: p); #expect(c + p == "ㅇ")
        (c, p) = applyInput("ㅇ", committed: c, composing: p); #expect(c + p == "ㅁ")
        (c, p) = applyInput("ㅇ", committed: c, composing: p); #expect(c + p == "ㅇ")
    }
    
    // MARK: - 2. 모음 조합 테스트 (천,지,인 키 활용)
    
    @Test("모음 조합: ㅣ + ㆍ = ㅏ")
    func test모음조합_아() {
        var (c, p) = ("", "")
        (c, p) = applyInput(인, committed: c, composing: p) // ㅣ
        (c, p) = applyInput(천, committed: c, composing: p) // ㅣ + ㆍ -> ㅏ
        
        #expect(c + p == "ㅏ")
    }
    
    @Test("모음 조합: ㆍ + ㅡ = ㅗ")
    func test모음조합_오() {
        var (c, p) = ("", "")
        (c, p) = applyInput(천, committed: c, composing: p) // ㆍ
        (c, p) = applyInput(지, committed: c, composing: p) // ㆍ + ㅡ -> ㅗ
        
        #expect(c + p == "ㅗ")
    }
    
    @Test("모음 생성 흐름: ㅡ -> ㅜ(ㆍ) -> ㅠ(ㆍ) -> ㅝ(ㅣ) -> ㅞ(ㅣ)")
    func test모음생성_복합() {
        var (c, p) = ("", "")
        
        (c, p) = applyInput(지, committed: c, composing: p) // ㅡ
        #expect(c + p == "ㅡ")
        
        (c, p) = applyInput(천, committed: c, composing: p) // ㅡ + ㆍ -> ㅜ
        #expect(c + p == "ㅜ")
        
        (c, p) = applyInput(천, committed: c, composing: p) // ㅜ + ㆍ -> ㅠ
        #expect(c + p == "ㅠ")
        
        (c, p) = applyInput(인, committed: c, composing: p) // ㅠ + ㅣ -> ㅝ
        #expect(c + p == "ㅝ")
        
        (c, p) = applyInput(인, committed: c, composing: p) // ㅝ + ㅣ -> ㅞ
        #expect(c + p == "ㅞ")
    }
    
    // MARK: - 3. 단어 생성 및 삭제 시나리오
    
    @Test("시나리오: '가니' 생성 후 삭제 -> '가ㄴ' (종성 복원 방지 확인)")
    func testScenario_가니_삭제() {
        var (c, p) = ("", "")
        
        // 1. '가' 만들기 (ㄱ + ㅣ + ㆍ)
        (c, p) = applyInput("ㄱ", committed: c, composing: p) // ㄱ
        (c, p) = applyInput(인, committed: c, composing: p)   // 기
        (c, p) = applyInput(천, committed: c, composing: p)   // 가
        
        // Space로 확정
        _ = processor.inputSpace(composing: p)
        c += p
        p = ""
        
        // 2. '가니' 만들기 (가 + ㄴ + ㅣ)
        (c, p) = applyInput("ㄴ", committed: c, composing: p) // 가ㄴ (ㄴ은 새 조합)
        (c, p) = applyInput(인, committed: c, composing: p)   // 가니
        
        #expect(c + p == "가니")
        
        // 3. 삭제 (ㅣ 삭제) -> '가ㄴ'이어야 함 ('간'으로 합쳐지면 안 됨)
        p = processor.delete(composing: p)
        #expect(c + p == "가ㄴ")
    }
    
    @Test("시나리오: '달거' -> 삭제 -> '닭'")
    func testScenario_달거_삭제_닭() {
        var (c, p) = ("", "")
        
        // 1. '닭' 만들기
        (c, p) = applyInput("ㄷ", committed: c, composing: p)
        (c, p) = applyInput(인, committed: c, composing: p)
        (c, p) = applyInput(천, committed: c, composing: p) // 다
        (c, p) = applyInput("ㄴ", committed: c, composing: p) // 단
        (c, p) = applyInput("ㄴ", committed: c, composing: p) // 달 (ㄴ->ㄹ)
        (c, p) = applyInput("ㄱ", committed: c, composing: p) // 닭
        
        // 2. '달거' 만들기 (닭 + ㆍ + ㅣ)
        (c, p) = applyInput(천, committed: c, composing: p) // 연음 대기
        (c, p) = applyInput(인, committed: c, composing: p) // 달거
        
        #expect(c + p == "달거")
        
        // 3. 삭제 -> '닭'으로 복원
        (c, p) = applyDelete(committed: c, composing: p)
        #expect(c + p == "닭")
    }
    
    @Test("시나리오: '학교' (스페이스바 확정 활용)")
    func testScenario_학교_Space() {
        var (c, p) = ("", "")
        
        // 1. '학'
        (c, p) = applyInput("ㅅ", committed: c, composing: p)
        (c, p) = applyInput("ㅅ", committed: c, composing: p) // ㅎ
        (c, p) = applyInput(인, committed: c, composing: p)
        (c, p) = applyInput(천, committed: c, composing: p) // 하
        (c, p) = applyInput("ㄱ", committed: c, composing: p) // 학
        
        #expect(c + p == "학")
        
        // 2. Space (확정)
        _ = processor.inputSpace(composing: p)
        c += p
        p = ""
        
        // 3. '교' (ㄱ + ㆍ + ㆍ + ㅡ)
        (c, p) = applyInput("ㄱ", committed: c, composing: p) // 학ㄱ
        (c, p) = applyInput(천, committed: c, composing: p)   // 학ㄱㆍ
        (c, p) = applyInput(천, committed: c, composing: p)   // 학ㄱᆢ
        (c, p) = applyInput(지, committed: c, composing: p)   // 학교
        
        #expect(c + p == "학교")
    }
    
    @Test("시나리오: '와' 만들기 (ㅇ + ㆍ + ㅡ + ㅣ + ㆍ)")
    func testScenario_와() {
        var (c, p) = ("", "")
        
        (c, p) = applyInput("ㅇ", committed: c, composing: p)
        (c, p) = applyInput(천, committed: c, composing: p)
        (c, p) = applyInput(지, committed: c, composing: p)
        #expect(c + p == "오")
        
        (c, p) = applyInput(인, committed: c, composing: p)
        #expect(c + p == "외")
        
        (c, p) = applyInput(천, committed: c, composing: p)
        #expect(c + p == "와")
    }
    
    // MARK: - 4. 11,172자 전체 검증 (Heavy Test)
    
    @Test("천지인 11,172자 전체 생성 및 삭제 검증")
    func validateAllCharacters() {
        let 한글Start = 0xAC00; let 한글End = 0xD7A3
        var failureCount = 0
        
        for unicode in 한글Start...한글End {
            guard let scalar = Unicode.Scalar(unicode) else { continue }
            let char = Character(scalar)
            let targetString = String(char)
            
            let keySequence = decomposeTo천지인Keys(char: char)
            
            var (committed, composing) = ("", "")
            for key in keySequence {
                (committed, composing) = applyInput(key, committed: committed, composing: composing)
            }
            
            if committed + composing != targetString {
                Self.logger.error("실패: \(targetString) (생성됨: \(committed + composing)) / 입력키: \(keySequence)")
                failureCount += 1
            }
        }
        
        #expect(failureCount == 0, "총 \(failureCount)개의 글자 생성 실패")
    }
}

// MARK: - Test Helpers

private extension CheonjiinProcessorTests {
    
    /// 프로세서 입력 후 `committed`/`composing`을 누적하는 헬퍼
    func applyInput(_ char: String, committed: String, composing: String) -> (committed: String, composing: String) {
        let hadPreviousComposing = !composing.isEmpty
        let result = processor.input(글자Input: char, composing: composing)
        var c = committed + result.committed
        let p = result.composing
        
        if hadPreviousComposing && result.committed.isEmpty && p.count == 1 && !c.isEmpty {
            if let restored = tryRestore종성(자음: p, committed: &c) {
                return (c, restored)
            }
        }
        
        return (c, p)
    }
    
    /// ViewController의 `deleteBackward`를 시뮬레이션하는 삭제 헬퍼
    func applyDelete(committed: String, composing: String) -> (committed: String, composing: String) {
        var c = committed
        var p = composing
        
        if !p.isEmpty {
            p = processor.delete(composing: p)
            
            if let restored = tryRestore종성(자음: p, committed: &c) {
                return (c, restored)
            }
        } else if !c.isEmpty {
            c.removeLast()
        }
        
        return (c, p)
    }
    
    func tryRestore종성(자음: String, committed: inout String) -> String? {
        guard 자음.count == 1, !committed.isEmpty else { return nil }
        guard automata.종성Table.contains(자음) && 자음 != " " else { return nil }
        guard let lastCommitted = committed.last,
              let _ = automata.decompose(한글Char: lastCommitted) else { return nil }
        
        let lastCommittedStr = String(lastCommitted)
        let (committed2, merged) = automata.add글자(글자Input: 자음, composing: lastCommittedStr)
        let mergedText = committed2 + merged
        
        if mergedText.count == 1 {
            committed.removeLast()
            return mergedText
        }
        return nil
    }
    
    /// 완성된 한글 한 글자를 천지인 키 입력 배열로 분해
    func decomposeTo천지인Keys(char: Character) -> [String] {
        guard let scalar = char.unicodeScalars.first else { return [] }
        let code = Int(scalar.value) - 0xAC00
        
        let 초 = code / (21 * 28)
        let 중 = (code % (21 * 28)) / 28
        let 종 = code % 28
        
        var keys: [String] = []
        
        keys.append(contentsOf: get초성Keys(index: 초))
        keys.append(contentsOf: get중성Keys(index: 중))
        
        if 종 != 0 {
            keys.append(contentsOf: get종성Keys(index: 종))
        }
        
        return keys
    }
    
    func get초성Keys(index: Int) -> [String] {
        switch index {
        case 0: return ["ㄱ"]
        case 1: return ["ㄱ", "ㄱ", "ㄱ"]
        case 2: return ["ㄴ"]
        case 3: return ["ㄷ"]
        case 4: return ["ㄷ", "ㄷ", "ㄷ"]
        case 5: return ["ㄴ", "ㄴ"]
        case 6: return ["ㅇ", "ㅇ"]
        case 7: return ["ㅂ"]
        case 8: return ["ㅂ", "ㅂ", "ㅂ"]
        case 9: return ["ㅅ"]
        case 10: return ["ㅅ", "ㅅ", "ㅅ"]
        case 11: return ["ㅇ"]
        case 12: return ["ㅈ"]
        case 13: return ["ㅈ", "ㅈ", "ㅈ"]
        case 14: return ["ㅈ", "ㅈ"]
        case 15: return ["ㄱ", "ㄱ"]
        case 16: return ["ㄷ", "ㄷ"]
        case 17: return ["ㅂ", "ㅂ"]
        case 18: return ["ㅅ", "ㅅ"]
        default: return []
        }
    }
    
    func get중성Keys(index: Int) -> [String] {
        let 천 = "ㆍ"
        let 지 = "ㅡ"
        let 인 = "ㅣ"
        
        switch index {
        case 0: return [인, 천]
        case 1: return [인, 천, 인]
        case 2: return [인, 천, 천]
        case 3: return [인, 천, 천, 인]
        case 4: return [천, 인]
        case 5: return [천, 인, 인]
        case 6: return [천, 인, 천]
        case 7: return [천, 인, 천, 인]
        case 8: return [천, 지]
        case 9: return [천, 지, 인, 천]
        case 10: return [천, 지, 인, 천, 인]
        case 11: return [천, 지, 인]
        case 12: return [천, 천, 지]
        case 13: return [지, 천]
        case 14: return [지, 천, 천, 인]
        case 15: return [지, 천, 천, 인, 인]
        case 16: return [지, 천, 인]
        case 17: return [지, 천, 천]
        case 18: return [지]
        case 19: return [지, 인]
        case 20: return [인]
        default: return []
        }
    }
    
    func get종성Keys(index: Int) -> [String] {
        switch index {
        case 1: return ["ㄱ"]
        case 2: return ["ㄱ", "ㄱ", "ㄱ"]
        case 3: return ["ㄱ", "ㅅ"]
        case 4: return ["ㄴ"]
        case 5: return ["ㄴ", "ㅈ"]
        case 6: return ["ㄴ", "ㅅ", "ㅅ"]
        case 7: return ["ㄷ"]
        case 8: return ["ㄴ", "ㄴ"]
        case 9: return ["ㄴ", "ㄴ", "ㄱ"]
        case 10: return ["ㄴ", "ㄴ", "ㅇ", "ㅇ"]
        case 11: return ["ㄴ", "ㄴ", "ㅂ"]
        case 12: return ["ㄴ", "ㄴ", "ㅅ"]
        case 13: return ["ㄴ", "ㄴ", "ㄷ", "ㄷ"]
        case 14: return ["ㄴ", "ㄴ", "ㅂ", "ㅂ"]
        case 15: return ["ㄴ", "ㄴ", "ㅅ", "ㅅ"]
        case 16: return ["ㅇ", "ㅇ"]
        case 17: return ["ㅂ"]
        case 18: return ["ㅂ", "ㅅ"]
        case 19: return ["ㅅ"]
        case 20: return ["ㅅ", "ㅅ", "ㅅ"]
        case 21: return ["ㅇ"]
        case 22: return ["ㅈ"]
        case 23: return ["ㅈ", "ㅈ"]
        case 24: return ["ㄱ", "ㄱ"]
        case 25: return ["ㄷ", "ㄷ"]
        case 26: return ["ㅂ", "ㅂ"]
        case 27: return ["ㅅ", "ㅅ"]
        default: return []
        }
    }
}
