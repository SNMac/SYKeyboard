//
//  NaratgeulProcessorTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 9/19/25.
//

import Testing

@testable import HangeulKeyboard

@Suite("나랏글 입력기 검증")
struct NaratgeulProcessorTests {
    
    // MARK: - Properties
    
    private let processor: NaratgeulProcessorProtocol = NaratgeulProcessor()
    
    // MARK: - Helper Method (테스트 편의성을 위해 추가)
    
    /// Processor의 input 결과를 텍스트만 반환하도록 감싸는 헬퍼
    private func input(_ char: String, to text: String) -> String {
        let result = processor.input(글자Input: char, beforeText: text)
        return result.0 // (String, String?) 중 앞의 String(전체 텍스트)만 반환
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
}
