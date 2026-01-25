//
//  DubeolsikProcessorTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 1/23/26.
//

import Testing
import OSLog

@testable import HangeulKeyboardCore

@Suite("두벌식 입력기 검증")
struct DubeolsikProcessorTests {
    
    // MARK: - Properties
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: "DubeolsikProcessorTests"))
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    private let processor: HangeulProcessable
    
    private let 초성Table = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    private let 중성Table = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
    private let 종성Table = [" ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let 겹모음조합Table: [(앞모음: String, 뒷모음: String, 겹모음: String)] = [
        ("ㅗ", "ㅏ", "ㅘ"), ("ㅘ", "ㅣ", "ㅙ"), ("ㅗ", "ㅐ", "ㅙ"), ("ㅗ", "ㅣ", "ㅚ"),
        ("ㅜ", "ㅓ", "ㅝ"), ("ㅜ", "ㅔ", "ㅞ"), ("ㅝ", "ㅣ", "ㅞ"), ("ㅜ", "ㅣ", "ㅟ"), ("ㅡ", "ㅣ", "ㅢ")
    ]
    
    private let 겹자음조합Table: [(앞자음: String, 뒷자음: String, 겹자음: String)] = [
        ("ㄱ", "ㅅ", "ㄳ"), ("ㄴ", "ㅈ", "ㄵ"), ("ㄴ", "ㅎ", "ㄶ"), ("ㄹ", "ㄱ", "ㄺ"),
        ("ㄹ", "ㅁ", "ㄻ"), ("ㄹ", "ㅂ", "ㄼ"), ("ㄹ", "ㅅ", "ㄽ"), ("ㄹ", "ㅌ", "ㄾ"),
        ("ㄹ", "ㅍ", "ㄿ"), ("ㄹ", "ㅎ", "ㅀ"), ("ㅂ", "ㅅ", "ㅄ")
    ]
    
    // MARK: - Initializer
    
    init() {
        self.processor = DubeolsikProcessor(automata: automata)
    }
    
    // MARK: - 1. 기본 입력 및 조합 테스트
    
    @Test("기본 입력: '가' 생성 (ㄱ + ㅏ)")
    func test기본입력_가() {
        var 텍스트 = ""
        텍스트 = input("ㄱ", to: 텍스트)
        텍스트 = input("ㅏ", to: 텍스트)
        
        #expect(텍스트 == "가")
    }
    
    @Test("종성 입력: '각' 생성 (가 + ㄱ)")
    func test기본입력_각() {
        var 텍스트 = ""
        텍스트 = input("ㄱ", to: 텍스트)
        텍스트 = input("ㅏ", to: 텍스트) // 가
        텍스트 = input("ㄱ", to: 텍스트) // 각
        
        #expect(텍스트 == "각")
    }
    
    @Test("복합 모음 입력: '와' 생성 (ㅇ + ㅗ + ㅏ)")
    func test복합모음_와() {
        var 텍스트 = ""
        텍스트 = input("ㅇ", to: 텍스트)
        텍스트 = input("ㅗ", to: 텍스트)
        텍스트 = input("ㅏ", to: 텍스트) // ㅗ + ㅏ -> ㅘ
        
        #expect(텍스트 == "와")
    }
    
    @Test("겹받침 입력: '닭' 생성 (ㄷ + ㅏ + ㄹ + ㄱ)")
    func test겹받침_닭() {
        var 텍스트 = ""
        텍스트 = input("ㄷ", to: 텍스트)
        텍스트 = input("ㅏ", to: 텍스트)
        텍스트 = input("ㄹ", to: 텍스트) // 달
        텍스트 = input("ㄱ", to: 텍스트) // 닭 (ㄹ + ㄱ -> ㄺ)
        
        #expect(텍스트 == "닭")
    }
    
    @Test("연음 입력: '안녕' (ㅇ+ㅏ+ㄴ+ㄴ+ㅕ+ㅇ)")
    func test연음입력_안녕() {
        var 텍스트 = ""
        let 입력배열 = ["ㅇ", "ㅏ", "ㄴ", "ㄴ", "ㅕ", "ㅇ"]
        
        for 자소 in 입력배열 {
            텍스트 = input(자소, to: 텍스트)
        }
        
        #expect(텍스트 == "안녕")
    }
    
    // MARK: - 2. 스페이스바 및 특수문자 동작 테스트
    
    @Test("Space 입력: 항상 insertSpace 반환 및 공백 입력")
    func test스페이스_동작() {
        // 1. 조합 중이 아닐 때
        let 결과1 = processor.inputSpace(beforeText: "가")
        #expect(결과1 == .insertSpace, "조합 중이 아닐 때도 insertSpace여야 함")
        
        // 2. 조합 중일 때 (두벌식은 조합 상태와 무관하게 띄어쓰기)
        let 결과2 = processor.inputSpace(beforeText: "ㄱ")
        #expect(결과2 == .insertSpace, "자음만 입력된 상태에서도 insertSpace여야 함")
    }
    
    @Test("비한글 입력: 숫자/특수문자 입력 시 단순 추가")
    func test비한글_입력() {
        var 텍스트 = ""
        텍스트 = input("ㄱ", to: 텍스트)
        #expect(텍스트 == "ㄱ")
        
        // 숫자 입력 -> 조합 끊기고 추가
        텍스트 = input("1", to: 텍스트)
        #expect(텍스트 == "ㄱ1")
        
        텍스트 = input("ㅏ", to: 텍스트)
        #expect(텍스트 == "ㄱ1ㅏ")
    }
    
    // MARK: - 3. 삭제(Backspace) 테스트
    
    @Test("삭제: '닭' -> '달' -> '다' -> 'ㄷ' -> ''")
    func test삭제_흐름_닭() {
        // 1. 닭 생성
        var 텍스트 = "닭"
        
        // 2. 삭제 1회: 닭(ㄺ) -> 달(ㄹ)
        텍스트 = processor.delete(beforeText: 텍스트)
        #expect(텍스트 == "달")
        
        // 3. 삭제 2회: 달 -> 다
        텍스트 = processor.delete(beforeText: 텍스트)
        #expect(텍스트 == "다")
        
        // 4. 삭제 3회: 다 -> ㄷ
        텍스트 = processor.delete(beforeText: 텍스트)
        #expect(텍스트 == "ㄷ")
        
        // 5. 삭제 4회: ㄷ -> ""
        텍스트 = processor.delete(beforeText: 텍스트)
        #expect(텍스트 == "")
    }
    
    @Test("삭제: '와' -> '오' -> 'ㅇ' -> ''")
    func test삭제_흐름_와() {
        // 1. 와 생성
        var 텍스트 = "와"
        
        // 2. 삭제 1회: 와(ㅘ) -> 오(ㅗ)
        텍스트 = processor.delete(beforeText: 텍스트)
        #expect(텍스트 == "오")
        
        // 3. 삭제 2회: 오 -> ㅇ
        텍스트 = processor.delete(beforeText: 텍스트)
        #expect(텍스트 == "ㅇ")
        
        // 4. 삭제 3회: ㅇ -> ""
        텍스트 = processor.delete(beforeText: 텍스트)
        #expect(텍스트 == "")
    }
    
    // MARK: - 4. 11,172자 전체 검증 (Heavy Test)
    
    @Test("두벌식 11,172자 전체 생성 및 삭제 검증")
    func validateAll두벌식한글글자() {
        let 한글시작 = 0xAC00
        let 한글끝 = 0xD7A3
        var 실패횟수 = 0
        
        Self.logger.info("[Swift Testing - \(#function)] 11,172자 전체 검증 시작...")
        
        for 유니코드 in 한글시작...한글끝 {
            guard let 스칼라 = Unicode.Scalar(유니코드) else { continue }
            let 목표글자Char = Character(스칼라)
            let 목표글자String = String(목표글자Char)
            
            // 1. 두벌식 입력 시퀀스로 변환 (예: 닭 -> ㄷ, ㅏ, ㄹ, ㄱ)
            let 입력키배열 = decompose두벌식키분해(char: 목표글자Char)
            
            // 2. 입력 시뮬레이션
            var 현재텍스트 = ""
            for 키 in 입력키배열 {
                현재텍스트 = processor.input(글자Input: 키, beforeText: 현재텍스트).processedText
            }
            
            // 3. 생성 검증
            if 현재텍스트 != 목표글자String {
                Self.logger.error("생성 실패: 목표(\(목표글자String)) != 결과(\(현재텍스트)) / 입력: \(입력키배열)")
                실패횟수 += 1
                continue
            }
            
            // 4. 삭제 시뮬레이션
            // 입력한 키의 개수만큼 백스페이스를 눌렀을 때 빈 문자열로 돌아가야 함
            var 삭제테스트텍스트 = 현재텍스트
            for _ in 0..<입력키배열.count {
                삭제테스트텍스트 = processor.delete(beforeText: 삭제테스트텍스트)
            }
            
            if !삭제테스트텍스트.isEmpty {
                Self.logger.error("삭제 실패: \(목표글자String) -> 잔여물: '\(삭제테스트텍스트)'")
                실패횟수 += 1
            }
        }
        
        #expect(실패횟수 == 0, "총 \(실패횟수)개의 글자에서 오류 발생")
        
        if 실패횟수 == 0 {
            Self.logger.info("[Swift Testing - \(#function)] 11,172자 검증 완료.")
        }
    }
}

// MARK: - Test Helpers

private extension DubeolsikProcessorTests {
    
    /// 단순 입력 헬퍼 (Text만 반환)
    func input(_ char: String, to text: String) -> String {
        return processor.input(글자Input: char, beforeText: text).processedText
    }
    
    /// 완성된 한글 문자를 두벌식 키 입력 배열로 분해
    func decompose두벌식키분해(char: Character) -> [String] {
        guard let scalar = char.unicodeScalars.first else { return [] }
        let 한글값 = Int(scalar.value) - 0xAC00
        
        let 초성Index = 한글값 / (21 * 28)
        let 중성Index = (한글값 % (21 * 28)) / 28
        let 종성Index = 한글값 % 28
        
        var 입력키배열: [String] = []
        
        // 1. 초성
        입력키배열.append(초성Table[초성Index])
        
        // 2. 중성 (재귀적으로 낱자 분해)
        let 중성Char = 중성Table[중성Index]
        입력키배열.append(contentsOf: decompose모음_재귀(중성Char))
        
        // 3. 종성 (겹받침 분해)
        if 종성Index != 0 {
            let 종성Char = 종성Table[종성Index]
            입력키배열.append(contentsOf: decompose자음_분해(종성Char))
        }
        
        return 입력키배열
    }
    
    /// 모음을 재귀적으로 분해 (예: ㅙ -> ㅘ, ㅣ -> ㅗ, ㅏ, ㅣ)
    func decompose모음_재귀(_ 모음: String) -> [String] {
        if ["ㅐ", "ㅔ", "ㅒ", "ㅖ"].contains(모음) { return [모음] }
        
        if let 조합 = 겹모음조합Table.first(where: { $0.겹모음 == 모음 }) {
            return decompose모음_재귀(조합.앞모음) + decompose모음_재귀(조합.뒷모음)
        } else {
            return [모음]
        }
    }
    
    /// 자음을 분해 (예: ㄳ -> ㄱ, ㅅ)
    func decompose자음_분해(_ 자음: String) -> [String] {
        if let 조합 = 겹자음조합Table.first(where: { $0.겹자음 == 자음 }) {
            return [조합.앞자음, 조합.뒷자음]
        } else {
            return [자음]
        }
    }
}
