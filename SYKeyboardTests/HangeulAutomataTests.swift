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
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
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
        ("ㅡ", "ㅣ", "ㅢ")
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
    func validateAll한글글자() {
        let 한글UnicodeStart = 0xAC00 // '가'
        let 한글UnicodeEnd = 0xD7A3   // '힣'
        
        Self.logger.info("[Swift Testing - \(#function)] 한글 11,172자 전체 검증 시작...")
        
        var failureCount = 0
        
        for 한글Unicode in 한글UnicodeStart...한글UnicodeEnd {
            // 1. 검증 대상 글자 준비
            guard let 한글Scalar = Unicode.Scalar(한글Unicode) else { continue }
            let target한글Char = Character(한글Scalar)
            let target한글String = String(target한글Char)
            
            // 2. 키 입력 시퀀스 추출 ('닭' -> "ㄷ", "ㅏ", "ㄹ", "ㄱ")
            let inputSequence = extract한글Inputs(for: target한글Char)
            
            // -------------------------------------------------
            // A. 입력 테스트
            // -------------------------------------------------
            var currentText = ""
            for input in inputSequence {
                currentText = automata.add글자(글자Input: input, beforeText: currentText)
            }
            
            if currentText != target한글String {
                Self.logger.error("생성 실패: 목표(\(target한글String)) != 결과(\(currentText)) / 입력: \(inputSequence)")
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
                    expectedText = automata.add글자(글자Input: input, beforeText: expectedText)
                }
                
                if deleteText != expectedText {
                    Self.logger.error("삭제 실패(\(target한글String)): 단계 \(i + 1) / 예상(\(expectedText)) != 결과(\(deleteText))")
                    failureCount += 1
                    break
                }
            }
        }
        
        // 최종 검증: 실패한 횟수가 0이어야 함
        #expect(failureCount == 0, "총 \(failureCount)개의 글자에서 로직 오류가 발생했습니다.")
        
        if failureCount == 0 {
            Self.logger.info("[Swift Testing - \(#function)] 한글 11,172자 검증 완료.")
        }
    }
    
    @Test("자모 단독 입력 및 겹모음/겹받침 조합 테스트")
    func validate자모Combinations() {
        Self.logger.info("[Swift Testing - \(#function)] 자모 조합/분해 테스트 시작...")
        
        // Case 1: 겹모음 조합 (ㅗ + ㅏ -> ㅘ)
        var text = ""
        
        // 1-1. 'ㅗ' 입력
        text = automata.add글자(글자Input: "ㅗ", beforeText: text)
        #expect(text == "ㅗ", "기대값: ㅗ, 실제값: \(text)")
        
        // 1-2. 'ㅏ' 입력 (조합 발생)
        text = automata.add글자(글자Input: "ㅏ", beforeText: text)
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
        text = automata.add글자(글자Input: "ㅗ", beforeText: text)
        text = automata.add글자(글자Input: "ㅏ", beforeText: text) // ㅘ
        
        text = automata.add글자(글자Input: "ㅣ", beforeText: text) // ㅘ + ㅣ -> ㅙ
        #expect(text == "ㅙ", "기대값: ㅙ, 실제값: \(text)")
        
        
        // Case 3: 겹모음이 불가능한 조합 (ㅜ + ㅏ -> ㅜ + ㅏ)
        // 오토마타 로직상 단순히 옆에 붙습니다.
        text = ""
        text = automata.add글자(글자Input: "ㅜ", beforeText: text)
        text = automata.add글자(글자Input: "ㅏ", beforeText: text)
        #expect(text == "ㅜㅏ", "기대값: ㅜㅏ (조합불가), 실제값: \(text)")
        
        
        // Case 4: 초성 입력 후 모음 입력 (ㄱ + ㅏ -> 가)
        text = ""
        text = automata.add글자(글자Input: "ㄱ", beforeText: text)
        #expect(text == "ㄱ", "기대값: ㄱ, 실제값: \(text)")
        
        text = automata.add글자(글자Input: "ㅏ", beforeText: text)
        #expect(text == "가", "기대값: 가, 실제값: \(text)")
        
        // 4-1. 삭제 (가 -> ㄱ)
        text = automata.delete글자(beforeText: text)
        #expect(text == "ㄱ", "기대값: ㄱ (자음만 남음), 실제값: \(text)")
        
        Self.logger.info("[Swift Testing - \(#function)] 자모 조합 테스트 완료.")
    }
    
    @Test("특수문자, 숫자, 영어 입력 및 한글 조합 끊김 테스트")
    func validateNon한글Inputs() {
        Self.logger.info("[Swift Testing - \(#function)] 비한글 문자 테스트 시작...")
        
        var text = ""
        
        // Case 1: 숫자와 특수문자 단순 입력 및 삭제
        text = automata.add글자(글자Input: "1", beforeText: text)
        text = automata.add글자(글자Input: ".", beforeText: text)
        text = automata.add글자(글자Input: "A", beforeText: text)
        #expect(text == "1.A", "기대값: 1.A, 실제값: \(text)")
        
        text = automata.delete글자(beforeText: text) // 'A' 삭제
        #expect(text == "1.", "기대값: 1., 실제값: \(text)")
        
        // Case 2: 한글 입력 도중 비한글 문자가 들어오면 조합이 끊겨야 함
        // 'ㄱ' + 'a' + 'ㅏ' -> '가'가 되면 안 되고 'ㄱaㅏ'가 되어야 함
        text = ""
        text = automata.add글자(글자Input: "ㄱ", beforeText: text)
        #expect(text == "ㄱ")
        
        text = automata.add글자(글자Input: "a", beforeText: text) // 조합 중단됨
        #expect(text == "ㄱa")
        
        text = automata.add글자(글자Input: "ㅏ", beforeText: text) // 새로운 글자로 시작
        #expect(text == "ㄱaㅏ", "비한글 문자가 한글 조합을 끊어야 함")
        
        // Case 3: 완성된 한글 뒤에 특수문자 입력
        // '한' + '!' -> '한!'
        text = ""
        text = automata.add글자(글자Input: "ㅎ", beforeText: text)
        text = automata.add글자(글자Input: "ㅏ", beforeText: text)
        text = automata.add글자(글자Input: "ㄴ", beforeText: text)
        #expect(text == "한")
        
        text = automata.add글자(글자Input: "!", beforeText: text)
        #expect(text == "한!", "완성된 한글 뒤에 특수문자가 붙어야 함")
        
        text = automata.delete글자(beforeText: text) // '!' 삭제
        #expect(text == "한", "특수문자만 삭제되고 한글은 유지되어야 함")
        
        text = automata.delete글자(beforeText: text) // '한' -> '하' (종성 삭제)
        #expect(text == "하", "한글 분해 로직이 다시 동작해야 함")
        
        Self.logger.info("[Swift Testing - \(#function)] 비한글 문자 테스트 완료.")
    }
}

// MARK: - Private Methods

private extension HangeulAutomataTests {
    
    /// 완성된 한글 문자 하나를 받아서, 이를 만들기 위해 눌러야 할 키보드 입력 배열로 변환
    ///
    /// 재귀 호출을 통해 'ㅙ' -> 'ㅘ'+'ㅣ' -> 'ㅗ'+'ㅏ'+'ㅣ' 처럼 낱자 단위까지 분해합니다.
    func extract한글Inputs(for 한글: Character) -> [String] {
        guard let scalar = 한글.unicodeScalars.first else { return [] }
        let value = Int(scalar.value) - 0xAC00
        
        let choIndex = value / (21 * 28)
        let jungIndex = (value % (21 * 28)) / 28
        let jongIndex = value % 28
        
        var inputs: [String] = []
        
        // 1. 초성
        inputs.append(초성Table[choIndex])
        
        // 2. 중성 (재귀 필요 O: ㅙ -> ㅘ+ㅣ -> ㅗ+ㅏ+ㅣ)
        let jungChar = 중성Table[jungIndex]
        inputs.append(contentsOf: decompose모음Recursively(jungChar))
        
        // 3. 종성 (재귀 필요 X: 겹받침은 한 번만 쪼개면 됨)
        if jongIndex != 0 {
            let jongChar = 종성Table[jongIndex]
            inputs.append(contentsOf: decompose자음(jongChar))
        }
        
        return inputs
    }
    
    /// 모음을 재귀적으로 분해하는 헬퍼 메서드
    ///
    /// 예: ㅙ -> [ㅘ, ㅣ] -> [ㅗ, ㅏ, ㅣ]
    func decompose모음Recursively(_ 모음: String) -> [String] {
        if ["ㅐ", "ㅔ", "ㅒ", "ㅖ"].contains(모음) { return [모음] }
        
        if let match = 겹모음조합Table.first(where: { $0.겹모음 == 모음 }) {
            // 앞모음이 또 겹모음일 수 있으므로 재귀 호출 (예: ㅘ)
            return decompose모음Recursively(match.앞모음) + decompose모음Recursively(match.뒷모음)
        } else {
            return [모음]
        }
    }
    
    /// 자음을 분해하는 헬퍼 메서드
    ///
    /// 예: ㄳ -> [ㄱ, ㅅ]
    func decompose자음(_ 자음: String) -> [String] {
        if let match = 겹자음조합Table.first(where: { $0.겹자음 == 자음 }) {
            return [match.앞자음, match.뒷자음]
        } else {
            return [자음]
        }
    }
}
