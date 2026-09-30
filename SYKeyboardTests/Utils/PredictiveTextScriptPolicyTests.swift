//
//  PredictiveTextScriptPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("NGram 후보 문자 종류 판별 검증")
struct PredictiveTextScriptPolicyTests {

    @Test("한글이 하나라도 있으면 한글", arguments: ["오늘", "ㅋㅋ", "SY키보드", "iOS용", "ᄀ"])
    func test한글이하나라도있으면_한글(word: String) {
        #expect(PredictiveTextScriptPolicy.script(of: word) == .hangeul)
    }

    @Test("한글 없이 라틴 문자가 있으면 라틴", arguments: ["meeting", "café", "iOS18", "Straße", "don't"])
    func test한글없이라틴문자가있으면_라틴(word: String) {
        #expect(PredictiveTextScriptPolicy.script(of: word) == .latin)
    }

    @Test("한글도 라틴 문자도 없으면 기타", arguments: ["123", "😀", "×÷", "...", ""])
    func test한글도라틴문자도없으면_기타(word: String) {
        #expect(PredictiveTextScriptPolicy.script(of: word) == .other)
    }

    @Test("언어 모드 식별자에서 선호 문자 종류를 정함")
    func test언어모드식별자에서_선호문자종류를정함() {
        #expect(PredictiveTextScriptPolicy.preferredScript(forLanguage: "ko-KR") == .hangeul)
        #expect(PredictiveTextScriptPolicy.preferredScript(forLanguage: "en-US") == .latin)
        #expect(PredictiveTextScriptPolicy.preferredScript(forLanguage: "ko-en") == nil)
    }
}
