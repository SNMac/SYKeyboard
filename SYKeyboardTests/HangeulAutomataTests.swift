//
//  HangeulAutomataTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 9/18/25.
//

import Testing
import OSLog

@testable import HangeulKeyboardCore

@Suite("한글 오토마타 검증")
struct HangeulAutomataTests {
    
    // MARK: - Properties
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: String(describing: "HangeulAutomataTests")
    )
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    // MARK: - 1. 한글 11,172자 전체 검증
    
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
            let inputSequence = DubeolsikKeyDecomposer.keys(for: target한글Char)
            
            // -------------------------------------------------
            // A. 입력 테스트
            // -------------------------------------------------
            var committed = ""
            var composing = ""
            for input in inputSequence {
                let result = automata.add글자(글자Input: input, composing: composing)
                committed += result.committed
                composing = result.composing
            }
            let currentText = committed + composing
            
            if currentText != target한글String {
                Self.logger.error("생성 실패: 목표(\(target한글String)) != 결과(\(currentText)) / 입력: \(inputSequence)")
                failureCount += 1
                continue
            }
            
            // -------------------------------------------------
            // B. 삭제 테스트
            // -------------------------------------------------
            // composing 부분에서만 삭제가 이뤄지므로, 입력 시퀀스를 역순으로 지워감
            var deleteCommitted = committed
            var deleteComposing = composing
            
            for i in 0..<inputSequence.count {
                deleteComposing = automata.delete글자(composing: deleteComposing)
                
                // composing이 비었으면 committed의 마지막 글자를 composing으로 이동
                if deleteComposing.isEmpty && !deleteCommitted.isEmpty {
                    deleteComposing = String(deleteCommitted.removeLast())
                }
                
                // 예상 값 계산: 입력 시퀀스에서 맨 뒤(i + 1개)를 뺀 나머지로 다시 만든 글자
                let remainingInputs = inputSequence.dropLast(i + 1)
                var expectedCommitted = ""
                var expectedComposing = ""
                for input in remainingInputs {
                    let result = automata.add글자(글자Input: input, composing: expectedComposing)
                    expectedCommitted += result.committed
                    expectedComposing = result.composing
                }
                let expectedText = expectedCommitted + expectedComposing
                let actualText = deleteCommitted + deleteComposing
                
                if actualText != expectedText {
                    Self.logger.error("삭제 실패(\(target한글String)): 단계 \(i + 1) / 예상(\(expectedText)) != 결과(\(actualText))")
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
    
    // MARK: - 2. 자모 조합/분해 검증
    
    @Test("자모 단독 입력 및 겹모음/겹받침 조합 테스트")
    func validate자모Combinations() {
        Self.logger.info("[Swift Testing - \(#function)] 자모 조합/분해 테스트 시작...")
        
        // Case 1: 겹모음 조합 (ㅗ + ㅏ -> ㅘ)
        var committed = ""
        var composing = ""
        
        // 1-1. 'ㅗ' 입력
        (committed, composing) = addAndAccumulate("ㅗ", committed: committed, composing: composing)
        #expect(committed + composing == "ㅗ", "기대값: ㅗ, 실제값: \(committed + composing)")
        
        // 1-2. 'ㅏ' 입력 (조합 발생)
        (committed, composing) = addAndAccumulate("ㅏ", committed: committed, composing: composing)
        #expect(committed + composing == "ㅘ", "기대값: ㅘ, 실제값: \(committed + composing)")
        
        // 1-3. 삭제 (분해 발생: ㅘ -> ㅗ)
        composing = automata.delete글자(composing: composing)
        #expect(committed + composing == "ㅗ", "기대값: ㅗ, 실제값: \(committed + composing)")
        
        // 1-4. 삭제 (삭제 발생: ㅗ -> "")
        composing = automata.delete글자(composing: composing)
        #expect(committed + composing == "", "기대값: 빈 문자열, 실제값: \(committed + composing)")
        
        
        // Case 2: 3중 모음 방지 및 분리 (ㅗ + ㅏ + ㅣ -> ㅘ + ㅣ -> ㅙ)
        committed = ""
        composing = ""
        (committed, composing) = addAndAccumulate("ㅗ", committed: committed, composing: composing)
        (committed, composing) = addAndAccumulate("ㅏ", committed: committed, composing: composing) // ㅘ
        
        (committed, composing) = addAndAccumulate("ㅣ", committed: committed, composing: composing) // ㅘ + ㅣ -> ㅙ
        #expect(committed + composing == "ㅙ", "기대값: ㅙ, 실제값: \(committed + composing)")
        
        
        // Case 3: 겹모음이 불가능한 조합 (ㅜ + ㅏ -> ㅜ + ㅏ)
        committed = ""
        composing = ""
        (committed, composing) = addAndAccumulate("ㅜ", committed: committed, composing: composing)
        (committed, composing) = addAndAccumulate("ㅏ", committed: committed, composing: composing)
        #expect(committed + composing == "ㅜㅏ", "기대값: ㅜㅏ (조합불가), 실제값: \(committed + composing)")
        
        
        // Case 4: 초성 입력 후 모음 입력 (ㄱ + ㅏ -> 가)
        committed = ""
        composing = ""
        (committed, composing) = addAndAccumulate("ㄱ", committed: committed, composing: composing)
        #expect(committed + composing == "ㄱ", "기대값: ㄱ, 실제값: \(committed + composing)")
        
        (committed, composing) = addAndAccumulate("ㅏ", committed: committed, composing: composing)
        #expect(committed + composing == "가", "기대값: 가, 실제값: \(committed + composing)")
        
        // 4-1. 삭제 (가 -> ㄱ)
        composing = automata.delete글자(composing: composing)
        #expect(committed + composing == "ㄱ", "기대값: ㄱ (자음만 남음), 실제값: \(committed + composing)")
        
        Self.logger.info("[Swift Testing - \(#function)] 자모 조합 테스트 완료.")
    }
    
    // MARK: - 3. 비한글 문자 검증
    
    @Test("특수문자, 숫자, 영어 입력 및 한글 조합 끊김 테스트")
    func validateNon한글Inputs() {
        Self.logger.info("[Swift Testing - \(#function)] 비한글 문자 테스트 시작...")
        
        var committed = ""
        var composing = ""
        
        // Case 1: 숫자와 특수문자 단순 입력 및 삭제
        (committed, composing) = addAndAccumulate("1", committed: committed, composing: composing)
        (committed, composing) = addAndAccumulate(".", committed: committed, composing: composing)
        (committed, composing) = addAndAccumulate("A", committed: committed, composing: composing)
        #expect(committed + composing == "1.A", "기대값: 1.A, 실제값: \(committed + composing)")
        
        composing = automata.delete글자(composing: composing) // 'A' 삭제
        if composing.isEmpty && !committed.isEmpty {
            composing = String(committed.removeLast())
        }
        #expect(committed + composing == "1.", "기대값: 1., 실제값: \(committed + composing)")
        
        // Case 2: 한글 입력 도중 비한글 문자가 들어오면 조합이 끊겨야 함
        committed = ""
        composing = ""
        (committed, composing) = addAndAccumulate("ㄱ", committed: committed, composing: composing)
        #expect(committed + composing == "ㄱ")
        
        (committed, composing) = addAndAccumulate("a", committed: committed, composing: composing) // 조합 중단됨
        #expect(committed + composing == "ㄱa")
        
        (committed, composing) = addAndAccumulate("ㅏ", committed: committed, composing: composing) // 새로운 글자로 시작
        #expect(committed + composing == "ㄱaㅏ", "비한글 문자가 한글 조합을 끊어야 함")
        
        // Case 3: 완성된 한글 뒤에 특수문자 입력
        committed = ""
        composing = ""
        (committed, composing) = addAndAccumulate("ㅎ", committed: committed, composing: composing)
        (committed, composing) = addAndAccumulate("ㅏ", committed: committed, composing: composing)
        (committed, composing) = addAndAccumulate("ㄴ", committed: committed, composing: composing)
        #expect(committed + composing == "한")
        
        (committed, composing) = addAndAccumulate("!", committed: committed, composing: composing)
        #expect(committed + composing == "한!", "완성된 한글 뒤에 특수문자가 붙어야 함")
        
        composing = automata.delete글자(composing: composing) // '!' 삭제
        if composing.isEmpty && !committed.isEmpty {
            composing = String(committed.removeLast())
        }
        #expect(committed + composing == "한", "특수문자만 삭제되고 한글은 유지되어야 함")
        
        composing = automata.delete글자(composing: composing) // '한' -> '하' (종성 삭제)
        #expect(committed + composing == "하", "한글 분해 로직이 다시 동작해야 함")
        
        Self.logger.info("[Swift Testing - \(#function)] 비한글 문자 테스트 완료.")
    }
}

// MARK: - Test Helper Methods

private extension HangeulAutomataTests {
    
    /// 오토마타에 글자를 추가하고 committed/composing을 누적하는 헬퍼
    func addAndAccumulate(_ input: String, committed: String, composing: String) -> (committed: String, composing: String) {
        let result = automata.add글자(글자Input: input, composing: composing)
        return (committed + result.committed, result.composing)
    }
}
