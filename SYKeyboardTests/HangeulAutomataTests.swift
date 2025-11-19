//
//  HangeulAutomataTests.swift
//  HangeulAutomataTests
//
//  Created by 서동환 on 9/18/25.
//

import Testing
import OSLog

@testable import HangeulKeyboard

@Suite("한글 키보드 입력 검증")
struct HangeulAutomataTests {
    
    // MARK: - Properties
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: "HangeulAutomataTests"))
    
    private let automata = HangeulAutomata()
    
    private let 초성Table = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    private let 중성Table = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
    private let 종성Table = [" ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let 겹모음조합Table: [(앞모음: String, 뒷모음: String, 겹모음: String)] = [
        ("ㅗ", "ㅏ", "ㅘ"),
        ("ㅘ", "ㅣ", "ㅙ"),
        ("ㅗ", "ㅐ", "ㅙ"),
        ("ㅗ", "ㅣ", "ㅚ"),
        ("ㅜ", "ㅓ", "ㅝ"),
        ("ㅜ", "ㅔ", "ㅞ"),
        ("ㅝ", "ㅣ", "ㅞ"),
        ("ㅜ", "ㅣ", "ㅟ"),
        ("ㅡ", "ㅣ", "ㅢ"),
        ("ㅏ", "ㅣ", "ㅐ"),
        ("ㅓ", "ㅣ", "ㅔ"),
        ("ㅕ", "ㅣ", "ㅖ"),
        ("ㅑ", "ㅣ", "ㅒ")
    ]
    
    private let 겹자음조합Table: [(앞자음: String, 뒷자음: String, 겹자음: String)] = [
        ("ㄱ", "ㅅ", "ㄳ"),
        ("ㄴ", "ㅈ", "ㄵ"),
        ("ㄴ", "ㅎ", "ㄶ"),
        ("ㄹ", "ㄱ", "ㄺ"),
        ("ㄹ", "ㅁ", "ㄻ"),
        ("ㄹ", "ㅂ", "ㄼ"),
        ("ㄹ", "ㅅ", "ㄽ"),
        ("ㄹ", "ㅌ", "ㄾ"),
        ("ㄹ", "ㅍ", "ㄿ"),
        ("ㄹ", "ㅎ", "ㅀ"),
        ("ㅂ", "ㅅ", "ㅄ")
    ]
    
    // MARK: - Test Methods
    
    @Test("한글 11,172자 전체 생성 및 삭제 로직 검증")
    func validateAllHangeulCharacters() {
        let startCode = 0xAC00 // '가'
        let endCode = 0xD7A3   // '힣'
        
        Self.logger.info("[Swift Testing - \(#function)] 한글 11,172자 전체 검증 시작")
        
        var failureCount = 0
        
        for code in startCode...endCode {
            // 1. 검증 대상 글자 준비
            guard let scalar = Unicode.Scalar(code) else { continue }
            let targetChar = Character(scalar)
            let targetString = String(targetChar)
            
            // 2. 키 입력 시퀀스 추출 ('닭' -> "ㄷ", "ㅏ", "ㄹ", "ㄱ")
            let inputSequence = extractKeyInputs(for: targetChar)
            
            // -------------------------------------------------
            // A. 입력 테스트
            // -------------------------------------------------
            var currentText = ""
            for input in inputSequence {
                currentText = automata.add글자(beforeText: currentText, 글자Input: input)
            }
            
            if currentText != targetString {
                Self.logger.error("생성 실패: 목표(\(targetString)) != 결과(\(currentText)) / 입력: \(inputSequence)")
                failureCount += 1
                continue // 생성이 실패하면 삭제 테스트는 의미 없으므로 넘어감
            }
            
            // -------------------------------------------------
            // B. 삭제 테스트
            // -------------------------------------------------
            var deleteText = currentText
            
            // 입력한 횟수만큼 백스페이스 실행
            for i in 0..<inputSequence.count {
                deleteText = automata.delete글자(beforeText: deleteText)
                
                // 예상 값 계산: 입력 시퀀스에서 맨 뒤(i + 1개)를 뺀 나머지로 다시 만든 글자
                let remainingInputs = inputSequence.dropLast(i + 1)
                var expectedText = ""
                for input in remainingInputs {
                    expectedText = automata.add글자(beforeText: expectedText, 글자Input: input)
                }
                
                if deleteText != expectedText {
                    Self.logger.error("삭제 실패(\(targetString)): 단계 \(i + 1) / 예상(\(expectedText)) != 결과(\(deleteText))")
                    failureCount += 1
                    break
                }
            }
        }
        
        // 최종 검증: 실패한 횟수가 0이어야 함
        #expect(failureCount == 0, "총 \(failureCount)개의 글자에서 로직 오류가 발생했습니다.")
        
        if failureCount == 0 {
            Self.logger.info("[Swift Testing - \(#function)] 한글 11,172자 검증 완료")
        }
    }
    
    @Test("자모 단독 입력 및 겹모음/겹받침 조합 테스트")
    func validateJamoCombinations() {
        Self.logger.info("[Swift Testing - \(#function)] 자모 조합/분해 테스트 시작")
        
        // Case 1: 겹모음 조합 (ㅗ + ㅏ -> ㅘ)
        var text = ""
        
        // 1-1. 'ㅗ' 입력
        text = automata.add글자(beforeText: text, 글자Input: "ㅗ")
        #expect(text == "ㅗ", "기대값: ㅗ, 실제값: \(text)")
        
        // 1-2. 'ㅏ' 입력 (조합 발생)
        text = automata.add글자(beforeText: text, 글자Input: "ㅏ")
        #expect(text == "ㅘ", "기대값: ㅘ, 실제값: \(text)")
        
        // 1-3. 삭제 (분해 발생: ㅘ -> ㅗ)
        text = automata.delete글자(beforeText: text)
        #expect(text == "ㅗ", "기대값: ㅗ, 실제값: \(text)")
        
        // 1-4. 삭제 (삭제 발생: ㅗ -> "")
        text = automata.delete글자(beforeText: text)
        #expect(text == "", "기대값: 빈 문자열, 실제값: \(text)")
        
        
        // Case 2: 3중 모음 방지 및 분리 (ㅗ + ㅏ + ㅣ -> ㅘ + ㅣ -> 왜?)
        // 설명: ㅗ+ㅏ=ㅘ 상태에서 ㅣ를 누르면 '왜'가 됩니다. (ㅙ)
        text = ""
        text = automata.add글자(beforeText: text, 글자Input: "ㅗ")
        text = automata.add글자(beforeText: text, 글자Input: "ㅏ") // ㅘ
        
        text = automata.add글자(beforeText: text, 글자Input: "ㅣ") // ㅘ + ㅣ -> ㅙ
        #expect(text == "ㅙ", "기대값: ㅙ, 실제값: \(text)")
        
        
        // Case 3: 겹모음이 불가능한 조합 (ㅜ + ㅏ -> ㅜ + ㅏ)
        // 오토마타 로직상 단순히 옆에 붙습니다.
        text = ""
        text = automata.add글자(beforeText: text, 글자Input: "ㅜ")
        text = automata.add글자(beforeText: text, 글자Input: "ㅏ")
        #expect(text == "ㅜㅏ", "기대값: ㅜㅏ (조합불가), 실제값: \(text)")
        
        
        // Case 4: 초성 입력 후 모음 입력 (ㄱ + ㅏ -> 가)
        text = ""
        text = automata.add글자(beforeText: text, 글자Input: "ㄱ")
        #expect(text == "ㄱ", "기대값: ㄱ, 실제값: \(text)")
        
        text = automata.add글자(beforeText: text, 글자Input: "ㅏ")
        #expect(text == "가", "기대값: 가, 실제값: \(text)")
        
        // 4-1. 삭제 (가 -> ㄱ)
        text = automata.delete글자(beforeText: text)
        #expect(text == "ㄱ", "기대값: ㄱ (자음만 남음), 실제값: \(text)")
        
        Self.logger.info("[Swift Testing - \(#function)] 자모 조합 테스트 완료.")
    }
}

// MARK: - Private Methods

private extension HangeulAutomataTests {
    
    /// 완성된 한글 문자 하나를 받아서, 이를 만들기 위해 눌러야 할 키보드 입력 배열로 변환
    /// 예: '닭' -> ["ㄷ", "ㅏ", "ㄹ", "ㄱ"]
    func extractKeyInputs(for char: Character) -> [String] {
        guard let scalar = char.unicodeScalars.first else { return [] }
        let value = Int(scalar.value) - 0xAC00
        
        let choIndex = value / (21 * 28)
        let jungIndex = (value % (21 * 28)) / 28
        let jongIndex = value % 28
        
        var inputs: [String] = []
        
        // 1. 초성
        inputs.append(초성Table[choIndex])
        
        // 2. 중성
        let jungChar = 중성Table[jungIndex]
        
        // "ㅘ"를 만들기 위해 필요한 앞/뒷모음을 찾음
        if let match = 겹모음조합Table.first(where: { $0.겹모음 == jungChar }) {
            inputs.append(match.앞모음)
            inputs.append(match.뒷모음)
        } else {
            inputs.append(jungChar)
        }
        
        // 3. 종성
        if jongIndex != 0 {
            let jongChar = 종성Table[jongIndex]
            
            // "ㄳ"을 만들기 위해 필요한 앞/뒷자음을 찾음
            if let match = 겹자음조합Table.first(where: { $0.겹자음 == jongChar }) {
                inputs.append(match.앞자음)
                inputs.append(match.뒷자음)
            } else {
                inputs.append(jongChar)
            }
        }
        
        return inputs
    }
}
