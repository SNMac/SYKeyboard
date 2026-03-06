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
            "ㄴ": ["ㄴ"], "ㄷ": ["ㄴ", "획"], "ㅌ": ["ㄴ", "획", "획"], "ㄸ": ["ㄴ", "쌍"],
            "ㄹ": ["ㄹ"],
            "ㅁ": ["ㅁ"], "ㅂ": ["ㅁ", "획"], "ㅍ": ["ㅁ", "획", "획"], "ㅃ": ["ㅁ", "쌍"],
            "ㅅ": ["ㅅ"], "ㅈ": ["ㅅ", "획"], "ㅊ": ["ㅅ", "획", "획"], "ㅉ": ["ㅅ", "획", "획", "획"], "ㅆ": ["ㅅ", "쌍"],
            "ㅇ": ["ㅇ"], "ㅎ": ["ㅇ", "획"]
        ]
    }
    
    var 나랏글모음Map: [String: [String]] {
        [
            "ㅏ": ["ㅏ"], "ㅑ": ["ㅏ", "획"],
            "ㅓ": ["ㅓ"], "ㅕ": ["ㅓ", "획"],
            "ㅗ": ["ㅗ"], "ㅛ": ["ㅗ", "획"],
            "ㅜ": ["ㅜ"], "ㅠ": ["ㅜ", "획"],
            "ㅡ": ["ㅡ"], "ㅣ": ["ㅣ"],
            "ㅐ": ["ㅏ", "ㅣ"], "ㅒ": ["ㅏ", "획", "ㅣ"],
            "ㅔ": ["ㅓ", "ㅣ"], "ㅖ": ["ㅓ", "획", "ㅣ"],
            "ㅘ": ["ㅗ", "ㅏ"], "ㅙ": ["ㅗ", "ㅏ", "ㅣ"],
            "ㅚ": ["ㅗ", "ㅣ"],
            "ㅝ": ["ㅜ", "ㅓ"], "ㅞ": ["ㅜ", "ㅓ", "ㅣ"],
            "ㅟ": ["ㅜ", "ㅣ"],
            "ㅢ": ["ㅡ", "ㅣ"]
        ]
    }
    
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
        var (c, p) = ("", "")
        (c, p) = applyInput("ㄱ", committed: c, composing: p)
        #expect(c + p == "ㄱ")
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "ㅋ")
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "ㄱ")
    }
    
    @Test("획추가: 자음 4단계 순환 테스트 (ㅅ 계열)")
    func test자음획추가_ㅅ계열() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㅅ", committed: c, composing: p)
        #expect(c + p == "ㅅ")
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "ㅈ")
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "ㅊ")
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "ㅉ")
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "ㅅ")
    }
    
    @Test("획추가: 모음 변환 (ㅏ -> ㅑ)")
    func test모음획추가() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㅏ", committed: c, composing: p)
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "ㅑ")
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "ㅏ")
    }
    
    // MARK: - 2. 쌍자음 테스트
    
    @Test("쌍자음: 자음 그룹핑 테스트 (ㅁ, ㅂ, ㅍ -> ㅃ)")
    func test쌍자음_그룹핑() {
        // 1. ㅁ -> ㅃ
        var (c, p) = applyInput("ㅁ", committed: "", composing: "")
        (c, p) = applyInput("쌍", committed: c, composing: p)
        #expect(c + p == "ㅃ")
        
        // 2. ㅂ -> ㅃ
        (c, p) = applyInput("ㅂ", committed: "", composing: "")
        (c, p) = applyInput("쌍", committed: c, composing: p)
        #expect(c + p == "ㅃ")
        
        // 3. ㅍ -> ㅃ
        (c, p) = applyInput("ㅍ", committed: "", composing: "")
        (c, p) = applyInput("쌍", committed: c, composing: p)
        #expect(c + p == "ㅃ")
        
        // 4. ㅃ -> ㅁ (복귀)
        (c, p) = applyInput("쌍", committed: c, composing: p)
        #expect(c + p == "ㅁ")
    }
    
    @Test("쌍자음: ㅇ 예외 처리 (ㅇ -> ㅎ)")
    func test쌍자음_ㅇ예외() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㅇ", committed: c, composing: p)
        (c, p) = applyInput("쌍", committed: c, composing: p)
        #expect(c + p == "ㅎ")
        
        (c, p) = applyInput("쌍", committed: c, composing: p)
        #expect(c + p == "ㅇ")
    }
    
    // MARK: - 3. ㅏ/ㅓ, ㅗ/ㅜ 토글 테스트
    
    @Test("토글: ㅏ/ㅓ 반복 입력 시 교체")
    func testToggle_ㅏㅓ() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㅏ", committed: c, composing: p)
        #expect(c + p == "ㅏ")
        
        (c, p) = applyInput("ㅏ", committed: c, composing: p)
        #expect(c + p == "ㅓ")
        
        (c, p) = applyInput("ㅏ", committed: c, composing: p)
        #expect(c + p == "ㅏ")
    }
    
    @Test("토글: ㅗ/ㅜ 반복 입력 시 교체")
    func testToggle_ㅗㅜ() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㅗ", committed: c, composing: p)
        #expect(c + p == "ㅗ")
        
        (c, p) = applyInput("ㅗ", committed: c, composing: p)
        #expect(c + p == "ㅜ")
        
        (c, p) = applyInput("ㅗ", committed: c, composing: p)
        #expect(c + p == "ㅗ")
    }
    
    // MARK: - 4. 모음 결합 테스트 ('ㅣ' 추가)
    
    @Test("'ㅣ' 키 입력 시 모음 결합 및 연음 테스트")
    func test모음결합() {
        var (c, p) = ("", "")
        
        // 1. 낱자 결합: ㅏ + ㅣ -> ㅐ
        (c, p) = applyInput("ㅏ", committed: c, composing: p)
        (c, p) = applyInput("ㅣ", committed: c, composing: p)
        #expect(c + p == "ㅐ")
        
        // 2. 완성형 결합: 아 + ㅣ -> 애
        (c, p) = ("", "")
        (c, p) = applyInput("ㅇ", committed: c, composing: p)
        (c, p) = applyInput("ㅏ", committed: c, composing: p) // 아
        (c, p) = applyInput("ㅣ", committed: c, composing: p) // 애
        #expect(c + p == "애")
        
        // 3. 종성이 있는 경우 연음: 안 + ㅣ -> 아니
        (c, p) = ("", "")
        (c, p) = applyInput("ㅇ", committed: c, composing: p)
        (c, p) = applyInput("ㅏ", committed: c, composing: p)
        (c, p) = applyInput("ㄴ", committed: c, composing: p) // 안
        (c, p) = applyInput("ㅣ", committed: c, composing: p) // 아니
        #expect(c + p == "아니")
    }
    
    // MARK: - 5. 완성형 글자 변환 테스트
    
    @Test("완성형 글자: 종성이 있는 경우 (종성 변환)")
    func test완성형_종성변환() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㄱ", committed: c, composing: p)
        (c, p) = applyInput("ㅏ", committed: c, composing: p)
        (c, p) = applyInput("ㄱ", committed: c, composing: p) // 각
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "갘")
    }
    
    @Test("완성형 글자: 종성이 없는 경우 (중성 변환)")
    func test완성형_중성변환() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㄱ", committed: c, composing: p)
        (c, p) = applyInput("ㅏ", committed: c, composing: p) // 가
        
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "갸")
    }
    
    @Test("완성형 글자: 변환 불가 시 (유지)")
    func test완성형_변환불가() {
        var (c, p) = ("", "")
        (c, p) = applyInput("ㄱ", committed: c, composing: p)
        (c, p) = applyInput("ㅡ", committed: c, composing: p) // 그
        
        (c, p) = applyInput("쌍", committed: c, composing: p)
        #expect(c + p == "그")
    }
    
    // MARK: - 6. 복합 시나리오
    
    @Test("나랏글 입력 시나리오: 잠꼬대")
    func testScenario_잠꼬대() {
        var (c, p) = ("", "")
        
        // 1. '잠' 만들기
        (c, p) = applyInput("ㅅ", committed: c, composing: p)
        (c, p) = applyInput("획", committed: c, composing: p) // ㅈ
        (c, p) = applyInput("ㅏ", committed: c, composing: p) // 자
        (c, p) = applyInput("ㅁ", committed: c, composing: p) // 잠
        #expect(c + p == "잠")
        
        // 2. '꼬' 만들기
        (c, p) = applyInput("ㄱ", committed: c, composing: p) // 잠ㄱ
        (c, p) = applyInput("쌍", committed: c, composing: p) // 잠ㄲ
        (c, p) = applyInput("ㅗ", committed: c, composing: p) // 잠꼬
        #expect(c + p == "잠꼬")
        
        // 3. '대' 만들기
        (c, p) = applyInput("ㄴ", committed: c, composing: p) // 잠꼰
        (c, p) = applyInput("획", committed: c, composing: p) // 잠꼳 (ㄴ->ㄷ)
        (c, p) = applyInput("ㅏ", committed: c, composing: p) // 잠꼬다 (연음)
        (c, p) = applyInput("ㅣ", committed: c, composing: p) // 잠꼬대 (ㅏ+ㅣ=ㅐ)
        
        #expect(c + p == "잠꼬대")
    }
    
    // MARK: - 7. 반복 입력용 문자 반환 테스트
    
    @Test("반복 입력을 위한 입력 문자 반환값 검증")
    func testReturnInputChar() {
        // 1. 일반 입력: 'ㄱ' -> input글자 == 'ㄱ'
        let res1 = processor.input(글자Input: "ㄱ", composing: "")
        #expect(res1.input글자 == "ㄱ")
        
        // 2. 획추가: 'ㄱ' + '획' -> 'ㅋ', input글자 'ㅋ'
        let res2 = processor.input(글자Input: "획", composing: "ㄱ")
        #expect(res2.committed + res2.composing == "ㅋ")
        #expect(res2.input글자 == "ㅋ")
        
        // 3. 모음 토글: 'ㅏ' + 'ㅏ' -> 'ㅓ', input글자 'ㅓ'
        let res3 = processor.input(글자Input: "ㅏ", composing: "ㅏ")
        #expect(res3.committed + res3.composing == "ㅓ")
        #expect(res3.input글자 == "ㅓ")
        
        // 4. 모음 결합: 'ㅗ' + 'ㅣ' -> 'ㅚ', input글자 'ㅣ'
        let res4 = processor.input(글자Input: "ㅣ", composing: "ㅗ")
        #expect(res4.committed + res4.composing == "ㅚ")
        #expect(res4.input글자 == "ㅣ")
    }
    
    // MARK: - 8. 겹받침 분해 및 복원 테스트
    
    @Test("겹받침 분해 및 복원: 닭 <-> 달ㅋ")
    func test겹받침분해_복원() {
        var (c, p) = ("", "")
        
        // 1. '닭' 만들기
        (c, p) = applyInput("ㄷ", committed: c, composing: p)
        (c, p) = applyInput("ㅏ", committed: c, composing: p)
        (c, p) = applyInput("ㄹ", committed: c, composing: p) // 달
        (c, p) = applyInput("ㄱ", committed: c, composing: p) // 닭
        #expect(c + p == "닭")
        
        // 2. 닭 + 획 -> 달ㅋ (분해)
        (c, p) = applyInput("획", committed: c, composing: p)
        #expect(c + p == "달ㅋ")
        
        // 3. 달ㅋ + 획 -> 닭 (복원: ㅋ -> ㄱ, 달+ㄱ -> 닭)
        // 획추가로 ㅋ->ㄱ이 되면 낱자 자음 "ㄱ"이 남고, committed "달"과 합쳐져서 "닭"이 됨
        (c, p) = applyInput("획", committed: c, composing: p)
        // 프로세서가 "ㅋ" -> "ㄱ"으로 변환, 오토마타가 "달" + "ㄱ" 결합 시도
        // 결과: committed에 "달"이 있고 composing에 "ㄱ"이 있을 수 있으므로 합산 확인
        #expect(c + p == "닭")
    }
    
    // MARK: - 9. 나랏글 11,172자 전체 검증 (Heavy Test)
    
    @Test("나랏글 11,172자 전체 생성 및 삭제 검증")
    func validateAll나랏글한글글자() {
        let 한글UnicodeStart = 0xAC00
        let 한글UnicodeEnd = 0xD7A3
        
        Self.logger.info("[Swift Testing - \(#function)] 11,172자 전체 검증 시작...")
        
        var failureCount = 0
        
        for 한글Unicode in 한글UnicodeStart...한글UnicodeEnd {
            guard let 한글Scalar = Unicode.Scalar(한글Unicode) else { continue }
            let targetChar = Character(한글Scalar)
            let targetString = String(targetChar)
            
            // 1. 나랏글 입력 시퀀스로 변환
            let inputSequence = convertTo나랏글입력(for: targetChar)
            
            // 2. 입력 테스트
            var (committed, composing) = ("", "")
            for inputKey in inputSequence {
                (committed, composing) = applyInput(inputKey, committed: committed, composing: composing)
            }
            
            if committed + composing != targetString {
                Self.logger.error("생성 실패: 목표(\(targetString)) != 결과(\(committed + composing)) / 입력: \(inputSequence)")
                failureCount += 1
                continue
            }
            
            // 3. 삭제 테스트
            let expectedDeleteCount = calculateExpectedDeleteCount(for: targetChar)
            
            for _ in 0..<expectedDeleteCount {
                (committed, composing) = applyDelete(committed: committed, composing: composing)
            }
            
            if !(committed + composing).isEmpty {
                Self.logger.error("삭제 실패: \(targetString) -> 예상 삭제 횟수(\(expectedDeleteCount)) 실행 후 잔여물: '\(committed + composing)'")
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
    
    /// 프로세서 입력 후 `committed`/`composing`을 누적하는 헬퍼
    func applyInput(_ char: String, committed: String, composing: String) -> (committed: String, composing: String) {
        let hadPreviousComposing = !composing.isEmpty
        let result = processor.input(글자Input: char, composing: composing)
        var c = committed + result.committed
        var p = result.composing
        
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
            
            // 삭제 시 종성 복원
            if let restored = tryRestore종성(자음: p, committed: &c) {
                return (c, restored)
            }
        } else if !c.isEmpty {
            let lastCommitted = c.last!
            // 한글이면 composing으로 옮겨서 자소 단위 분해 삭제
            if automata.decompose(한글Char: lastCommitted) != nil {
                c.removeLast()
                p = processor.delete(composing: String(lastCommitted))
            } else {
                c.removeLast()
            }
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
        
        let 초성글자 = 초성Table[초성Index]
        if let mapped = 나랏글자음Map[초성글자] {
            inputs.append(contentsOf: mapped)
        }
        
        let 중성글자 = 중성Table[중성Index]
        if let mapped = 나랏글모음Map[중성글자] {
            inputs.append(contentsOf: mapped)
        }
        
        if 종성Index != 0 {
            let 종성글자 = 종성Table[종성Index]
            
            if let components = 종성겹받침Map[종성글자] {
                for component in components {
                    if let mapped = 나랏글자음Map[component] {
                        inputs.append(contentsOf: mapped)
                    }
                }
            } else {
                if let mapped = 나랏글자음Map[종성글자] {
                    inputs.append(contentsOf: mapped)
                }
            }
        }
        
        return inputs
    }
    
    /// 글자를 지우기 위해 필요한 백스페이스 횟수를 계산
    func calculateExpectedDeleteCount(for char: Character) -> Int {
        guard let scalar = char.unicodeScalars.first else { return 0 }
        let value = Int(scalar.value) - 0xAC00
        
        let 중성Index = (value % (21 * 28)) / 28
        let 종성Index = value % 28
        
        var count = 1
        
        let 중성Deletes: [Int] = [
            1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 3, 2, 1, 1, 2, 3, 2, 1, 1, 2, 1
        ]
        count += 중성Deletes[중성Index]
        
        if 종성Index != 0 {
            let 겹받침List = [3, 5, 6, 9, 10, 11, 12, 13, 14, 15, 18]
            if 겹받침List.contains(종성Index) {
                count += 2
            } else {
                count += 1
            }
        }
        
        return count
    }
}
