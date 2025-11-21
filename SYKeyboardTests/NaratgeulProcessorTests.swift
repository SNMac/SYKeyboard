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
    
    // MARK: - 1. 획추가 테스트
    
    @Test("획추가: 자음 순환 테스트 (ㄱ 계열)")
    func test자음획추가_ㄱ계열() {
        var text = ""
        text = processor.input(글자Input: "ㄱ", beforeText: text)
        #expect(text == "ㄱ")
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "ㅋ")
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "ㄱ")
    }
    
    @Test("획추가: 자음 4단계 순환 테스트 (ㅅ 계열)")
    func test자음획추가_ㅅ계열() {
        var text = ""
        text = processor.input(글자Input: "ㅅ", beforeText: text)
        #expect(text == "ㅅ")
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "ㅈ")
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "ㅊ")
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "ㅉ")
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "ㅅ")
    }
    
    @Test("획추가: 모음 변환 (ㅏ -> ㅑ)")
    func test모음획추가() {
        var text = ""
        text = processor.input(글자Input: "ㅏ", beforeText: text)
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "ㅑ")
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "ㅏ")
    }
    
    // MARK: - 2. 쌍자음 테스트
    
    @Test("쌍자음: 자음 그룹핑 테스트 (ㅁ, ㅂ, ㅍ -> ㅃ)")
    func test쌍자음_그룹핑() {
        var text = ""
        
        // 1. ㅁ -> ㅃ
        text = processor.input(글자Input: "ㅁ", beforeText: "")
        text = processor.input(글자Input: "쌍", beforeText: text)
        #expect(text == "ㅃ")
        
        // 2. ㅂ -> ㅃ
        text = processor.input(글자Input: "ㅂ", beforeText: "")
        text = processor.input(글자Input: "쌍", beforeText: text)
        #expect(text == "ㅃ")
        
        // 3. ㅍ -> ㅃ
        text = processor.input(글자Input: "ㅍ", beforeText: "")
        text = processor.input(글자Input: "쌍", beforeText: text)
        #expect(text == "ㅃ")
        
        // 4. ㅃ -> ㅁ (복귀)
        text = processor.input(글자Input: "쌍", beforeText: text)
        #expect(text == "ㅁ")
    }
    
    @Test("쌍자음: ㅇ 예외 처리 (ㅇ -> ㅎ)")
    func test쌍자음_ㅇ예외() {
        var text = ""
        text = processor.input(글자Input: "ㅇ", beforeText: text)
        text = processor.input(글자Input: "쌍", beforeText: text)
        #expect(text == "ㅎ")
        
        text = processor.input(글자Input: "쌍", beforeText: text)
        #expect(text == "ㅇ")
    }
    
    // MARK: - 3. ㅏ/ㅓ, ㅗ/ㅜ 토글 테스트
    
    @Test("토글: ㅏ/ㅓ 반복 입력 시 교체")
    func testToggle_ㅏㅓ() {
        var text = ""
        // 1. ㅏ 입력
        text = processor.input(글자Input: "ㅏ", beforeText: text)
        #expect(text == "ㅏ")
        
        // 2. ㅏ 다시 입력 -> ㅓ
        text = processor.input(글자Input: "ㅏ", beforeText: text)
        #expect(text == "ㅓ")
        
        // 3. ㅏ 다시 입력 -> ㅏ
        text = processor.input(글자Input: "ㅏ", beforeText: text)
        #expect(text == "ㅏ")
    }
    
    @Test("토글: ㅗ/ㅜ 반복 입력 시 교체")
    func testToggle_ㅗㅜ() {
        var text = ""
        // 1. ㅗ 입력
        text = processor.input(글자Input: "ㅗ", beforeText: text)
        #expect(text == "ㅗ")
        
        // 2. ㅗ 다시 입력 -> ㅜ
        text = processor.input(글자Input: "ㅗ", beforeText: text)
        #expect(text == "ㅜ")
        
        // 3. ㅗ 다시 입력 -> ㅗ
        text = processor.input(글자Input: "ㅗ", beforeText: text)
        #expect(text == "ㅗ")
    }
    
    // MARK: - 4. 모음 결합 테스트 ('ㅣ' 추가)
    
    @Test("'ㅣ' 키 입력 시 모음 결합 및 연음 테스트")
    func test모음결합() {
        var text = ""
        
        // 1. 낱자 결합: ㅏ + ㅣ -> ㅐ
        text = processor.input(글자Input: "ㅏ", beforeText: text)
        text = processor.input(글자Input: "ㅣ", beforeText: text)
        #expect(text == "ㅐ")
        
        // 2. 완성형 결합: 아 + ㅣ -> 애
        text = ""
        text = processor.input(글자Input: "ㅇ", beforeText: text)
        text = processor.input(글자Input: "ㅏ", beforeText: text) // 아
        text = processor.input(글자Input: "ㅣ", beforeText: text) // 애
        #expect(text == "애")
        
        // 3. 종성이 있는 경우 연음: 안 + ㅣ -> 아니
        text = ""
        text = processor.input(글자Input: "ㅇ", beforeText: text)
        text = processor.input(글자Input: "ㅏ", beforeText: text)
        text = processor.input(글자Input: "ㄴ", beforeText: text) // 안
        text = processor.input(글자Input: "ㅣ", beforeText: text) // 아니
        #expect(text == "아니", "받침이 있으면 연음 법칙이 적용되어야 함")
    }
    
    // MARK: - 5. 완성형 글자 변환 테스트
    
    @Test("완성형 글자: 종성이 있는 경우 (종성 변환)")
    func test완성형_종성변환() {
        // 각 + 획 -> 갘
        var text = ""
        text = processor.input(글자Input: "ㄱ", beforeText: text)
        text = processor.input(글자Input: "ㅏ", beforeText: text)
        text = processor.input(글자Input: "ㄱ", beforeText: text) // 각
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "갘")
    }
    
    @Test("완성형 글자: 종성이 없는 경우 (중성 변환)")
    func test완성형_중성변환() {
        // 가 + 획 -> 갸
        var text = ""
        text = processor.input(글자Input: "ㄱ", beforeText: text)
        text = processor.input(글자Input: "ㅏ", beforeText: text) // 가
        
        text = processor.input(글자Input: "획", beforeText: text)
        #expect(text == "갸")
    }
    
    @Test("완성형 글자: 변환 불가 시 (유지)")
    func test완성형_변환불가() {
        // 그 + 쌍 -> 그
        var text = ""
        text = processor.input(글자Input: "ㄱ", beforeText: text)
        text = processor.input(글자Input: "ㅡ", beforeText: text) // 그
        
        text = processor.input(글자Input: "쌍", beforeText: text)
        #expect(text == "그")
    }
    
    // MARK: - 6. 복합 시나리오
    
    @Test("나랏글 입력 시나리오: 잠꼬대")
    func testScenario_잠꼬대() {
        var text = ""
        
        // 1. '잠' 만들기
        // (ㅅ -> 획 -> ㅈ)
        text = processor.input(글자Input: "ㅅ", beforeText: text)
        text = processor.input(글자Input: "획", beforeText: text) // ㅈ
        text = processor.input(글자Input: "ㅏ", beforeText: text) // 자
        text = processor.input(글자Input: "ㅁ", beforeText: text) // 잠
        #expect(text == "잠")
        
        // 2. '꼬' 만들기
        // (잠 + ㄱ -> 잠ㄱ -> 쌍 -> 잠ㄲ -> ㅗ -> 잠꼬)
        text = processor.input(글자Input: "ㄱ", beforeText: text) // 잠ㄱ
        text = processor.input(글자Input: "쌍", beforeText: text) // 잠ㄲ
        text = processor.input(글자Input: "ㅗ", beforeText: text) // 잠꼬
        #expect(text == "잠꼬")
        
        // 3. '대' 만들기
        text = processor.input(글자Input: "ㄴ", beforeText: text) // 잠꼰
        text = processor.input(글자Input: "획", beforeText: text) // 잠꼳
        text = processor.input(글자Input: "ㅏ", beforeText: text) // 잠꼬다
        text = processor.input(글자Input: "ㅣ", beforeText: text) // 잠꼬대
        #expect(text == "잠꼬대")
    }
}
