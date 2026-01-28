//
//  NaratgeulProcessorTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 9/19/25.
//

import Testing
import OSLog

@testable import HangeulKeyboardCore

@Suite("나랏글 입력기 검증")
struct NaratgeulProcessorTests {
    
    // MARK: - Properties
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: String(describing: "NaratgeulProcessorTests")
    )
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    private let processor: HangeulProcessable
    
    var 나랏글자음Map: [String: [String]] {
        [
            "ㄱ": ["ㄱ"], "ㅋ": ["ㄱ", "획"], "ㄲ": ["ㄱ", "쌍"],
            "ㄴ": ["ㄴ"], "ㄷ": ["ㄴ", "획"], "ㅌ": ["ㄴ", "획", "획"], "ㄸ": ["ㄴ", "쌍"], // ㄸ은 ㄴ + 쌍 (또는 ㄷ + 쌍)
            "ㄹ": ["ㄹ"],
            "ㅁ": ["ㅁ"], "ㅂ": ["ㅁ", "획"], "ㅍ": ["ㅁ", "획", "획"], "ㅃ": ["ㅁ", "쌍"],
            "ㅅ": ["ㅅ"], "ㅈ": ["ㅅ", "획"], "ㅊ": ["ㅅ", "획", "획"], "ㅉ": ["ㅅ", "획", "획", "획"], "ㅆ": ["ㅅ", "쌍"], // ㅉ은 ㅅ 계열 4번째
            "ㅇ": ["ㅇ"], "ㅎ": ["ㅇ", "획"]
        ]
    }
    
    // 중성용 모음 맵
    var 나랏글모음Map: [String: [String]] {
        [
            "ㅏ": ["ㅏ"], "ㅑ": ["ㅏ", "획"],
            "ㅓ": ["ㅓ"], "ㅕ": ["ㅓ", "획"],
            "ㅗ": ["ㅗ"], "ㅛ": ["ㅗ", "획"],
            "ㅜ": ["ㅜ"], "ㅠ": ["ㅜ", "획"],
            "ㅡ": ["ㅡ"], "ㅣ": ["ㅣ"],
            
            // 복합 모음 (ㅏ/ㅓ, ㅗ/ㅜ, ㅣ 키 조합)
            "ㅐ": ["ㅏ", "ㅣ"], "ㅒ": ["ㅏ", "획", "ㅣ"], // ㅑ + ㅣ
            "ㅔ": ["ㅓ", "ㅣ"], "ㅖ": ["ㅓ", "획", "ㅣ"], // ㅕ + ㅣ
            
            "ㅘ": ["ㅗ", "ㅏ"], "ㅙ": ["ㅗ", "ㅏ", "ㅣ"], // ㅘ + ㅣ
            "ㅚ": ["ㅗ", "ㅣ"],
            
            "ㅝ": ["ㅜ", "ㅓ"], "ㅞ": ["ㅜ", "ㅓ", "ㅣ"], // ㅝ + ㅣ
            "ㅟ": ["ㅜ", "ㅣ"],
            
            "ㅢ": ["ㅡ", "ㅣ"]
        ]
    }
    
    // 종성 겹받침 맵
    var 종성겹받침Map: [String: [String]] {
        [
            "ㄳ": ["ㄱ", "ㅅ"], "ㄵ": ["ㄴ", "ㅈ"], "ㄶ": ["ㄴ", "ㅎ"],
            "ㄺ": ["ㄹ", "ㄱ"], "ㄻ": ["ㄹ", "ㅁ"], "ㄼ": ["ㄹ", "ㅂ"],
            "ㄽ": ["ㄹ", "ㅅ"], "ㄾ": ["ㄹ", "ㅌ"], "ㄿ": ["ㄹ", "ㅍ"],
            "ㅀ": ["ㄹ", "ㅎ"], "ㅄ": ["ㅂ", "ㅅ"]
        ]
    }
    
    // MARK: - Initializer
    
    init() {
        self.processor = NaratgeulProcessor(automata: automata)
    }
    
    // MARK: - 1. 획추가 테스트
    
    @Test("획추가: 자음 순환 테스트 (ㄱ 계열)")
    func test자음획추가_ㄱ계열() {
        // ㄱ -> ㅋ -> ㄱ
        var text = ""
        text = input("ㄱ", to: text)
        #expect(text == "ㄱ")
        
        text = input("획", to: text)
        #expect(text == "ㅋ")
        
        text = input("획", to: text)
        #expect(text == "ㄱ")
    }
    
    @Test("획추가: 자음 4단계 순환 테스트 (ㅅ 계열)")
    func test자음획추가_ㅅ계열() {
        // ㅅ -> ㅈ -> ㅊ -> ㅉ -> ㅅ
        var text = ""
        text = input("ㅅ", to: text)
        #expect(text == "ㅅ")
        
        text = input("획", to: text)
        #expect(text == "ㅈ")
        
        text = input("획", to: text)
        #expect(text == "ㅊ")
        
        text = input("획", to: text)
        #expect(text == "ㅉ")
        
        text = input("획", to: text)
        #expect(text == "ㅅ")
    }
    
    @Test("획추가: 모음 변환 (ㅏ -> ㅑ)")
    func test모음획추가() {
        var text = ""
        text = input("ㅏ", to: text)
        text = input("획", to: text)
        #expect(text == "ㅑ")
        
        text = input("획", to: text)
        #expect(text == "ㅏ") // 토글 확인
    }
    
    // MARK: - 2. 쌍자음 테스트
    
    @Test("쌍자음: 자음 그룹핑 테스트 (ㅁ, ㅂ, ㅍ -> ㅃ)")
    func test쌍자음_그룹핑() {
        // 1. ㅁ -> ㅃ
        var text = input("ㅁ", to: "")
        text = input("쌍", to: text)
        #expect(text == "ㅃ")
        
        // 2. ㅂ -> ㅃ
        text = input("ㅂ", to: "")
        text = input("쌍", to: text)
        #expect(text == "ㅃ")
        
        // 3. ㅍ -> ㅃ
        text = input("ㅍ", to: "")
        text = input("쌍", to: text)
        #expect(text == "ㅃ")
        
        // 4. ㅃ -> ㅁ (복귀)
        text = input("쌍", to: text) // 현재 ㅃ
        #expect(text == "ㅁ")
    }
    
    @Test("쌍자음: ㅇ 예외 처리 (ㅇ -> ㅎ)")
    func test쌍자음_ㅇ예외() {
        var text = ""
        text = input("ㅇ", to: text)
        text = input("쌍", to: text)
        #expect(text == "ㅎ")
        
        text = input("쌍", to: text)
        #expect(text == "ㅇ")
    }
    
    // MARK: - 3. ㅏ/ㅓ, ㅗ/ㅜ 토글 테스트
    
    @Test("토글: ㅏ/ㅓ 반복 입력 시 교체")
    func testToggle_ㅏㅓ() {
        var text = ""
        // 1. ㅏ 입력
        text = input("ㅏ", to: text)
        #expect(text == "ㅏ")
        
        // 2. ㅏ 다시 입력 -> ㅓ
        text = input("ㅏ", to: text)
        #expect(text == "ㅓ")
        
        // 3. ㅏ 다시 입력 -> ㅏ
        text = input("ㅏ", to: text)
        #expect(text == "ㅏ")
    }
    
    @Test("토글: ㅗ/ㅜ 반복 입력 시 교체")
    func testToggle_ㅗㅜ() {
        var text = ""
        // 1. ㅗ 입력
        text = input("ㅗ", to: text)
        #expect(text == "ㅗ")
        
        // 2. ㅗ 다시 입력 -> ㅜ
        text = input("ㅗ", to: text)
        #expect(text == "ㅜ")
        
        // 3. ㅗ 다시 입력 -> ㅗ
        text = input("ㅗ", to: text)
        #expect(text == "ㅗ")
    }
    
    // MARK: - 4. 모음 결합 테스트 ('ㅣ' 추가)
    
    @Test("'ㅣ' 키 입력 시 모음 결합 및 연음 테스트")
    func test모음결합() {
        var text = ""
        
        // 1. 낱자 결합: ㅏ + ㅣ -> ㅐ
        text = input("ㅏ", to: text)
        text = input("ㅣ", to: text)
        #expect(text == "ㅐ")
        
        // 2. 완성형 결합: 아 + ㅣ -> 애
        text = ""
        text = input("ㅇ", to: text)
        text = input("ㅏ", to: text) // 아
        text = input("ㅣ", to: text) // 애
        #expect(text == "애")
        
        // 3. 종성이 있는 경우 연음: 안 + ㅣ -> 아니
        text = ""
        text = input("ㅇ", to: text)
        text = input("ㅏ", to: text)
        text = input("ㄴ", to: text) // 안
        text = input("ㅣ", to: text) // 아니
        #expect(text == "아니")
    }
    
    // MARK: - 5. 완성형 글자 변환 테스트
    
    @Test("완성형 글자: 종성이 있는 경우 (종성 변환)")
    func test완성형_종성변환() {
        // 각 + 획 -> 갘
        var text = ""
        text = input("ㄱ", to: text)
        text = input("ㅏ", to: text)
        text = input("ㄱ", to: text) // 각
        
        text = input("획", to: text)
        #expect(text == "갘")
    }
    
    @Test("완성형 글자: 종성이 없는 경우 (중성 변환)")
    func test완성형_중성변환() {
        // 가 + 획 -> 갸
        var text = ""
        text = input("ㄱ", to: text)
        text = input("ㅏ", to: text) // 가
        
        text = input("획", to: text)
        #expect(text == "갸")
    }
    
    @Test("완성형 글자: 변환 불가 시 (유지)")
    func test완성형_변환불가() {
        // 그 + 쌍 -> 그
        var text = ""
        text = input("ㄱ", to: text)
        text = input("ㅡ", to: text) // 그
        
        text = input("쌍", to: text)
        #expect(text == "그")
    }
    
    // MARK: - 6. 복합 시나리오
    
    @Test("나랏글 입력 시나리오: 잠꼬대")
    func testScenario_잠꼬대() {
        var text = ""
        
        // 1. '잠' 만들기
        text = input("ㅅ", to: text)
        text = input("획", to: text) // ㅈ
        text = input("ㅏ", to: text) // 자
        text = input("ㅁ", to: text) // 잠
        #expect(text == "잠")
        
        // 2. '꼬' 만들기
        text = input("ㄱ", to: text) // 잠ㄱ
        text = input("쌍", to: text) // 잠ㄲ
        text = input("ㅗ", to: text) // 잠꼬
        #expect(text == "잠꼬")
        
        // 3. '대' 만들기
        text = input("ㄴ", to: text) // 잠꼰
        text = input("획", to: text) // 잠꼳 (ㄴ->ㄷ)
        text = input("ㅏ", to: text) // 잠꼬다 (연음)
        text = input("ㅣ", to: text) // 잠꼬대 (ㅏ+ㅣ=ㅐ)
        
        #expect(text == "잠꼬대")
    }
    
    // MARK: - 7. 반복 입력용 문자 반환 테스트
    
    @Test("반복 입력을 위한 입력 문자 반환값 검증")
    func testReturnInputChar() {
        // 1. 일반 입력: 'ㄱ' -> ('ㄱ', 'ㄱ')
        let res1 = processor.input(글자Input: "ㄱ", beforeText: "")
        #expect(res1.1 == "ㄱ")
        
        // 2. 획추가: 'ㄱ' + '획' -> 'ㅋ', 반환값 'ㅋ'
        let res2 = processor.input(글자Input: "획", beforeText: "ㄱ")
        #expect(res2.0 == "ㅋ")
        #expect(res2.1 == "ㅋ") // 획추가된 'ㅋ'이 반환되어야 함
        
        // 3. 모음 토글: 'ㅏ' + 'ㅏ' -> 'ㅓ', 반환값 'ㅓ'
        let res3 = processor.input(글자Input: "ㅏ", beforeText: "ㅏ")
        #expect(res3.0 == "ㅓ")
        #expect(res3.1 == "ㅓ")
        
        // 4. 모음 결합: 'ㅗ' + 'ㅣ' -> 'ㅚ', 반환값 'ㅣ'
        let res4 = processor.input(글자Input: "ㅣ", beforeText: "ㅗ")
        #expect(res4.0 == "ㅚ")
        #expect(res4.1 == "ㅣ")
    }
    
    // MARK: - 7. 겹받침 분해 및 복원 테스트
    
    @Test("겹받침 분해 및 복원: 닭 <-> 달ㅋ")
    func test겹받침분해_복원() {
        var text = ""
        
        // 1. '닭' 만들기 (ㄹ + ㄱ -> 닭)
        text = input("ㄷ", to: text)
        text = input("ㅏ", to: text)
        text = input("ㄹ", to: text) // 달
        text = input("ㄱ", to: text) // 닭
        #expect(text == "닭")
        
        // 2. 닭 + 획 -> 달ㅋ (분해)
        text = input("획", to: text)
        #expect(text == "달ㅋ")
        
        // 3. 달ㅋ + 획 -> 닭 (복원: ㅋ -> ㄱ, 달+ㄱ -> 닭)
        text = input("획", to: text)
        #expect(text == "닭")
    }
    
    // MARK: - 8. 나랏글 11,172자 전체 검증 (Heavy Test)
    
    @Test("나랏글 11,172자 전체 생성 및 삭제 검증")
    func validateAll나랏글한글글자() {
        let 한글UnicodeStart = 0xAC00 // '가'
        let 한글UnicodeEnd = 0xD7A3   // '힣'
        
        Self.logger.info("[Swift Testing - \(#function)] 11,172자 전체 검증 시작...")
        
        var failureCount = 0
        
        for 한글Unicode in 한글UnicodeStart...한글UnicodeEnd {
            // 1. 타겟 글자 준비
            guard let 한글Scalar = Unicode.Scalar(한글Unicode) else { continue }
            let targetChar = Character(한글Scalar)
            let targetString = String(targetChar)
            
            // 2. 나랏글 입력 시퀀스로 변환
            let inputSequence = convertTo나랏글입력(for: targetChar)
            
            // 3. 입력 테스트
            var currentText = ""
            for inputKey in inputSequence {
                currentText = processor.input(글자Input: inputKey, beforeText: currentText).processedText
            }
            
            if currentText != targetString {
                Self.logger.error("생성 실패: 목표(\(targetString)) != 결과(\(currentText)) / 입력: \(inputSequence)")
                failureCount += 1
                continue
            }
            
            // 4. 삭제 테스트
            // '획', '쌍' 입력 횟수와 무관하게, 글자의 논리적 깊이만큼만 삭제를 수행해야 함.
            let expectedDeleteCount = calculateExpectedDeleteCount(for: targetChar)
            var deleteText = currentText
            
            for _ in 0..<expectedDeleteCount {
                deleteText = processor.delete(beforeText: deleteText)
            }
            
            // 검증: 예상된 횟수만큼 지웠을 때 빈 문자열이 되어야 함
            if !deleteText.isEmpty {
                Self.logger.error("삭제 실패: \(targetString) -> 예상 삭제 횟수(\(expectedDeleteCount)) 실행 후 잔여물: '\(deleteText)'")
                failureCount += 1
            }
        }
        
        #expect(failureCount == 0, "총 \(failureCount)개의 글자에서 오류(생성 또는 삭제)가 발생했습니다.")
        
        if failureCount == 0 {
            Self.logger.info("[Swift Testing - \(#function)] 11,172자 생성 및 삭제 검증 완료.")
        }
    }
}

// MARK: - Test Helper Methods

private extension NaratgeulProcessorTests {
    /// Processor의 input 결과를 텍스트만 반환하도록 감싸는 헬퍼
    func input(_ char: String, to text: String) -> String {
        let result = processor.input(글자Input: char, beforeText: text)
        return result.0 // (String, String?) 중 앞의 String(전체 텍스트)만 반환
    }
    
    /// 완성형 한글 1자를 나랏글 입력 시퀀스로 변환
    func convertTo나랏글입력(for char: Character) -> [String] {
        guard let scalar = char.unicodeScalars.first else { return [] }
        let value = Int(scalar.value) - 0xAC00
        
        let 초성Index = value / (21 * 28)
        let 중성Index = (value % (21 * 28)) / 28
        let 종성Index = value % 28
        
        let 초성Table = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
        let 중성Table = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
        let 종성Table = [" ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
        
        var inputs: [String] = []
        
        // 1. 초성 변환
        let 초성글자 = 초성Table[초성Index]
        if let mapped = 나랏글자음Map[초성글자] {
            inputs.append(contentsOf: mapped)
        }
        
        // 2. 중성 변환
        let 중성글자 = 중성Table[중성Index]
        if let mapped = 나랏글모음Map[중성글자] {
            inputs.append(contentsOf: mapped)
        }
        
        // 3. 종성 변환
        if 종성Index != 0 {
            let 종성글자 = 종성Table[종성Index]
            
            // 3-1. 겹받침인 경우 (예: 닭 -> ㄹ, ㄱ 순서로 입력)
            if let components = 종성겹받침Map[종성글자] {
                for component in components {
                    if let mapped = 나랏글자음Map[component] {
                        inputs.append(contentsOf: mapped)
                    }
                }
            } else {
                // 3-2. 홑받침인 경우
                if let mapped = 나랏글자음Map[종성글자] {
                    inputs.append(contentsOf: mapped)
                }
            }
        }
        
        return inputs
    }
    
    /// 글자를 지우기 위해 필요한 백스페이스 횟수를 계산
    /// 규칙: 단일 자모(획/쌍 포함)는 1회, 복합 모음/겹받침은 구성 요소 수만큼
    func calculateExpectedDeleteCount(for char: Character) -> Int {
        guard let scalar = char.unicodeScalars.first else { return 0 }
        let value = Int(scalar.value) - 0xAC00
        
        let 중성Index = (value % (21 * 28)) / 28
        let 종성Index = value % 28
        
        // 1. 초성: 무조건 1회 삭제 (ㅋ, ㄲ 등도 단일 자음 취급)
        var count = 1
        
        // 2. 중성: 복합 모음 여부에 따라 횟수 추가
        // 나랏글 기준 복합 모음(결합으로 생성되는 모음)의 깊이 계산
        let 중성Deletes: [Int] = [
            1, // ㅏ
            2, // ㅐ (ㅏ+ㅣ)
            1, // ㅑ (ㅏ+획 -> 단일)
            2, // ㅒ (ㅑ+ㅣ -> 단일+결합 -> 2회)
            1, // ㅓ
            2, // ㅔ (ㅓ+ㅣ)
            1, // ㅕ (ㅓ+획 -> 단일)
            2, // ㅖ (ㅕ+ㅣ -> 단일+결합 -> 2회)
            1, // ㅗ
            2, // ㅘ (ㅗ+ㅏ)
            3, // ㅙ (ㅗ+ㅏ+ㅣ)
            2, // ㅚ (ㅗ+ㅣ)
            1, // ㅛ (ㅗ+획 -> 단일)
            1, // ㅜ
            2, // ㅝ (ㅜ+ㅓ)
            3, // ㅞ (ㅜ+ㅓ+ㅣ)
            2, // ㅟ (ㅜ+ㅣ)
            1, // ㅠ (ㅜ+획 -> 단일)
            1, // ㅡ
            2, // ㅢ (ㅡ+ㅣ)
            1  // ㅣ
        ]
        count += 중성Deletes[중성Index]
        
        // 3. 종성: 겹받침 여부에 따라 횟수 추가
        if 종성Index != 0 {
            // 겹받침 인덱스: 3(ㄳ), 5(ㄵ), 6(ㄶ), 9(ㄺ), 10(ㄻ), 11(ㄼ), 12(ㄽ), 13(ㄾ), 14(ㄿ), 15(ㅀ), 18(ㅄ)
            let 겹받침List = [3, 5, 6, 9, 10, 11, 12, 13, 14, 15, 18]
            if 겹받침List.contains(종성Index) {
                count += 2 // 겹받침은 2회
            } else {
                count += 1 // 홑받침(ㅋ, ㄲ 포함)은 1회
            }
        }
        
        return count
    }
}
