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
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: "CheonjiinProcessorTests"))
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    private let processor: HangeulProcessable = CheonjiinProcessor()
    
    private let 아래아문자 = "ㆍ"
    
    // 천지인 자음 입력 맵
    var 천지인자음Map: [String: [String]] {
        [
            "ㄱ": ["ㄱ"], "ㅋ": ["ㄱ", "ㄱ"], "ㄲ": ["ㄱ", "ㄱ", "ㄱ"],
            "ㄴ": ["ㄴ"], "ㄹ": ["ㄴ", "ㄴ"],
            "ㄷ": ["ㄷ"], "ㅌ": ["ㄷ", "ㄷ"], "ㄸ": ["ㄷ", "ㄷ", "ㄷ"],
            "ㅂ": ["ㅂ"], "ㅍ": ["ㅂ", "ㅂ"], "ㅃ": ["ㅂ", "ㅂ", "ㅂ"],
            "ㅅ": ["ㅅ"], "ㅎ": ["ㅅ", "ㅅ"], "ㅆ": ["ㅅ", "ㅅ", "ㅅ"],
            "ㅈ": ["ㅈ"], "ㅊ": ["ㅈ", "ㅈ"], "ㅉ": ["ㅈ", "ㅈ", "ㅈ"],
            "ㅇ": ["ㅇ"], "ㅁ": ["ㅇ", "ㅇ"]
        ]
    }
    
    // 천지인 모음 입력 맵
    var 천지인모음Map: [String: [String]] {
        [
            "ㅣ": ["ㅣ"],
            "ㅡ": ["ㅡ"],
            "ㅏ": ["ㅣ", "ㆍ"],
            "ㅑ": ["ㅣ", "ㆍ", "ㆍ"],
            "ㅓ": ["ㆍ", "ㅣ"],
            "ㅕ": ["ㆍ", "ㅣ", "ㆍ"],
            "ㅗ": ["ㆍ", "ㅡ"],
            "ㅛ": ["ㆍ", "ㅡ", "ㆍ"],
            "ㅜ": ["ㅡ", "ㆍ"],
            "ㅠ": ["ㅡ", "ㆍ", "ㆍ"],
            "ㅢ": ["ㅡ", "ㅣ"],
            
            "ㅐ": ["ㅣ", "ㆍ", "ㅣ"],
            "ㅔ": ["ㆍ", "ㅣ", "ㅣ"],
            "ㅒ": ["ㅣ", "ㆍ", "ㆍ", "ㅣ"],
            "ㅖ": ["ㆍ", "ㅣ", "ㆍ", "ㅣ"],
            
            "ㅘ": ["ㆍ", "ㅡ", "ㅣ", "ㆍ"],
            "ㅙ": ["ㆍ", "ㅡ", "ㅣ", "ㆍ", "ㅣ"],
            "ㅚ": ["ㆍ", "ㅡ", "ㅣ"],
            
            "ㅝ": ["ㅡ", "ㆍ", "ㆍ", "ㅣ"],
            "ㅞ": ["ㅡ", "ㆍ", "ㆍ", "ㅣ", "ㅣ"],
            "ㅟ": ["ㅡ", "ㆍ", "ㅣ"]
        ]
    }
    
    // 종성 겹받침 맵
    var 종성겹받침Map: [String: [String]] {
        [
            "ㄳ": ["ㄱ", "ㅅ"], "ㄵ": ["ㄴ", "ㅈ"], "ㄶ": ["ㄴ", "ㅅ", "ㅅ"],
            "ㄺ": ["ㄴ", "ㄴ", "ㄱ"], "ㄻ": ["ㄴ", "ㄴ", "ㅇ", "ㅇ"], "ㄼ": ["ㄴ", "ㄴ", "ㅂ"],
            "ㄽ": ["ㄴ", "ㄴ", "ㅅ"], "ㄾ": ["ㄴ", "ㄴ", "ㄷ", "ㄷ"], "ㄿ": ["ㄴ", "ㄴ", "ㅂ", "ㅂ"],
            "ㅀ": ["ㄴ", "ㄴ", "ㅅ", "ㅅ"], "ㅄ": ["ㅂ", "ㅅ"]
        ]
    }
    
    // MARK: - 1. 자음 순환 테스트 (기존 동일)
    @Test("자음 순환: ㄱ 계열")
    func test자음순환_ㄱ계열() {
        var text = ""
        text = input("ㄱ", to: text); #expect(text == "ㄱ")
        text = input("ㄱ", to: text); #expect(text == "ㅋ")
        text = input("ㄱ", to: text); #expect(text == "ㄲ")
        text = input("ㄱ", to: text); #expect(text == "ㄱ")
    }
    
    // MARK: - 2. 모음 조합 및 흐름 테스트
    
    @Test("모음 조합: 기본 및 이중모음")
    func test모음조합_기본() {
        var text = ""
        text = input("ㅣ", to: text); text = input(아래아문자, to: text); #expect(text == "ㅏ")
        text = ""; text = input(아래아문자, to: text); text = input("ㅡ", to: text); #expect(text == "ㅗ")
    }
    
    @Test("모음 생성 흐름: ㅜ -> ㅠ -> ㅝ -> ㅞ (연결성 검증)")
    func test모음생성_흐름() {
        var text = ""
        // 1. ㅡ
        text = input("ㅡ", to: text)
        #expect(text == "ㅡ")
        
        // 2. ㅡ + ㆍ = ㅜ
        text = input(아래아문자, to: text)
        #expect(text == "ㅜ")
        
        // 3. ㅜ + ㆍ = ㅠ
        text = input(아래아문자, to: text)
        #expect(text == "ㅠ")
        
        // 4. ㅠ + ㅣ = ㅝ  (이 부분이 끊기지 않아야 함)
        text = input("ㅣ", to: text)
        #expect(text == "ㅝ")
        
        // 5. ㅝ + ㅣ = ㅞ
        text = input("ㅣ", to: text)
        #expect(text == "ㅞ")
    }
    
    @Test("완성형 글자에서 ㆍ + ㆍ + ㅣ = ㅕ (교 입력 로직)")
    func test완성형_속기_교() {
        var text = ""
        // ㄱ + ㆍ + ㆍ + ㅡ = 교
        text = input("ㄱ", to: text)
        text = input("ㆍ", to: text); #expect(text == "ㄱㆍ")
        text = input("ㆍ", to: text); #expect(text == "ㄱᆢ")
        text = input("ㅡ", to: text)
        
        // 기대 결과: 'ㄱ' + 'ᆢ' + 'ㅡ' -> 'ㄱ' + 'ㅛ' -> '교'
        #expect(text == "교")
    }
    
    // MARK: - 3. 삭제 테스트
    
    @Test("삭제: 기본 모음은 통째로 삭제")
    func test삭제_모음통삭제() {
        var text = input("ㄱ", to: "")
        text = input("ㅣ", to: text)
        text = input(아래아문자, to: text) // 가
        
        text = processor.delete(beforeText: text)
        #expect(text == "ㄱ") // ㅏ 삭제
        
        text = processor.delete(beforeText: text)
        #expect(text == "") // ㄱ 삭제
    }
    
    @Test("삭제: 복합 모음은 역순 분해 (의 -> 으, 와 -> 오)")
    func test삭제_복합모음_분해() {
        // 1. '의' 삭제 테스트
        var text = input("ㅇ", to: "")
        text = input("ㅡ", to: text)
        text = input("ㅣ", to: text) // 의
        #expect(text == "의")
        
        // 의 -> 으 (분해됨)
        text = processor.delete(beforeText: text)
        #expect(text == "으")
        
        // 으 -> ㅇ (삭제됨)
        text = processor.delete(beforeText: text)
        #expect(text == "ㅇ")
        
        // 2. '와' 삭제 테스트
        text = input("ㅇ", to: "")
        text = input(아래아문자, to: text)
        text = input("ㅡ", to: text) // 오
        text = input("ㅣ", to: text) // 외 (오+ㅣ) -> 천지인 로직상 ㅗ+ㅣ=ㅚ
        // 다시 ㅘ를 만드려면: ㅗ + ㆍ = ㅘ
        text = input("ㅇ", to: "")
        text = input(아래아문자, to: text)
        text = input("ㅡ", to: text) // 오
        text = input(아래아문자, to: text) // ㅗ + ㆍ = ㅘ (CheonjiinProcessor에 로직 필요: ㅚ+ㆍ=ㅘ or ㅗ+ㆍ=ㅛ?)
        // 현재 로직상: ㅗ+ㆍ=ㅛ, ㅛ+ㅣ=ㅘ.
        // 혹은 ㅚ+ㆍ=ㅘ 로직이 있다면:
        
        // 테스트를 명확히 하기 위해 '과'를 ㅗ + ㅏ 로 만듦
        text = input("ㄱ", to: "")
        text = input(아래아문자, to: text)
        text = input("ㅡ", to: text) // 고
        text = input("ㅣ", to: text)
        text = input(아래아문자, to: text) // 과 (고 + ㅏ)
        #expect(text == "과")
        
        // 과 -> 고 (분해됨)
        text = processor.delete(beforeText: text)
        #expect(text == "고")
    }
    
    // MARK: - 4. 겹받침 결합 테스트
    
    @Test("자음 순환으로 겹받침 만들기 (흴 + ㅁ -> 흶)")
    func test겹받침_결합() {
        var text = ""
        // 1. 흐
        text = input("ㅎ", to: text)
        text = input("ㅡ", to: text)
        // 2. 흘 (흴)
        text = input("ㄴ", to: text) // 흔
        text = input("ㄴ", to: text) // 흘
        
        #expect(text == "흘")
        
        // 3. ㅁ 입력 (ㄹ + ㅁ -> ㄻ)
        // ㅁ을 만들기 위해 'ㅇ'을 두 번 눌러야 함
        text = input("ㅇ", to: text) // 흘ㅇ
        #expect(text == "흘ㅇ")
        
        text = input("ㅇ", to: text) // 흘ㅇ -> 흘ㅁ (순환) -> 흚 (결합)
        #expect(text == "흚")
    }
    
    // MARK: - 5. 시나리오 테스트
    
    @Test("천지인 입력 시나리오: 학교 (Space 활용)")
    func testScenario_학교() {
        var text = ""
        
        // 1. '학' 만들기
        text = input("ㅅ", to: text)
        text = input("ㅅ", to: text) // ㅎ
        text = input("ㅣ", to: text)
        text = input("ㆍ", to: text) // 하
        text = input("ㄱ", to: text) // 학
        #expect(text == "학")
        
        // 2. 조합 끊기 (Space 입력)
        // inputSpace 메서드를 호출하여 내부 상태(flag)를 변경
        let result = processor.inputSpace(beforeText: text)
        #expect(result == .commitCombination)
        
        // flag가 true인 상태에서 다음 글자 입력 시 분리되어야 함
        // 3. '교' 만들기 (ㄱ + ㆍ + ㅡ + ㆍ)
        text = input("ㄱ", to: text) // "학" + "ㄱ" -> "학ㄱ"
        #expect(text == "학ㄱ")
        
        text = input("ㆍ", to: text)
        text = input("ㅡ", to: text) // 학고
        text = input("ㆍ", to: text) // 학교
        
        #expect(text == "학교")
    }
    
    // MARK: - 6. 천지인 11,172자 전체 검증 (Heavy Test)
    
    @Test("천지인 11,172자 전체 생성 및 삭제 검증")
    func validateAll천지인한글글자() {
        let 한글Start = 0xAC00; let 한글End = 0xD7A3
        var failureCount = 0
        
        for unicode in 한글Start...한글End {
            guard let scalar = Unicode.Scalar(unicode) else { continue }
            let char = Character(scalar)
            let targetString = String(char)
            
            // 생성
            let inputSeq = convertTo천지인입력(for: char)
            var currentText = ""
            for key in inputSeq {
                currentText = processor.input(글자Input: key, beforeText: currentText).processedText
            }
            
            if currentText != targetString {
                Self.logger.error("생성 실패: \(targetString) != \(currentText)")
                failureCount += 1; continue
            }
            
            // 삭제
            let expectedCount = calculateExpectedDeleteCount(for: char)
            var deleteText = currentText
            for _ in 0..<expectedCount {
                deleteText = processor.delete(beforeText: deleteText)
            }
            
            if !deleteText.isEmpty {
                Self.logger.error("삭제 실패: \(targetString) 남음: \(deleteText)")
                failureCount += 1
            }
        }
        
        #expect(failureCount == 0, "오류 발생: \(failureCount)건")
    }
}

// MARK: - Test Helpers

private extension CheonjiinProcessorTests {
    func input(_ char: String, to text: String) -> String {
        return processor.input(글자Input: char, beforeText: text).0
    }
    
    func convertTo천지인입력(for char: Character) -> [String] {
        guard let scalar = char.unicodeScalars.first else { return [] }
        let value = Int(scalar.value) - 0xAC00
        let 초 = value / (21 * 28); let 중 = (value % (21 * 28)) / 28; let 종 = value % 28
        var res: [String] = []
        
        if let keys = 천지인자음Map[automata.초성Table[초]] { res.append(contentsOf: keys) }
        if let keys = 천지인모음Map[automata.중성Table[중]] { res.append(contentsOf: keys) }
        if 종 != 0 {
            let 종성 = automata.종성Table[종]
            if let comps = 종성겹받침Map[종성] { res.append(contentsOf: comps) }
            else if let keys = 천지인자음Map[종성] { res.append(contentsOf: keys) }
        }
        return res
    }
    
    func calculateExpectedDeleteCount(for char: Character) -> Int {
        let tempProcessor = CheonjiinProcessor()
        var text = String(char)
        var count = 0
        while !text.isEmpty {
            text = tempProcessor.delete(beforeText: text)
            count += 1
            if count > 10 { break }
        }
        return count
    }
}
