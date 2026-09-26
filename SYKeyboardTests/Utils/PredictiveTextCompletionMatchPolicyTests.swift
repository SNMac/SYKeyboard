//
//  PredictiveTextCompletionMatchPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("NGram 완성 후보 접두어 판정 검증")
struct PredictiveTextCompletionMatchPolicyTests {

    @Test("라틴 문자는 대소문자를 무시하고 접두어로 비교", arguments: [
        ("hello", "hel"), ("Hello", "hel"), ("SY키보드", "sy"), ("SY키보드", "sy키"), ("sy키보드", "SY키볻")
    ])
    func test라틴문자는_대소문자를무시하고_접두어로비교(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    @Test("마지막 받침은 다음 글자 초성으로도 봄", arguments: [
        ("키보드", "키볻"), ("가방", "갑"), ("값", "갑")
    ])
    func test마지막받침은_다음글자초성으로도봄(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    @Test("겹받침은 두 자음으로 나눠 봄", arguments: [
        ("달걀", "닭"), ("안주", "앉"), ("닭고기", "닭"), ("ㄳ", "ㄱ")
    ])
    func test겹받침은_두자음으로나눠봄(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    // "고\u{11A2}"는 한 Character다. 스칼라 단위로 떼야 한다
    @Test("끝에 붙은 천지인 조합 중 모음은 떼고 비교", arguments: [
        ("키보드", "킵\u{318D}"), ("키보드", "키ㅂ\u{318D}"), ("여기", "ㅇ\u{11A2}"), ("고양이", "고\u{11A2}")
    ])
    func test끝에붙은_천지인조합중모음은_떼고비교(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    @Test("이어 쓴 단어가 아니면 완성이 아님", arguments: [
        ("키보드", "킴"), ("과자", "고"), ("개발", "가"), ("help", "hex"), ("가", "각"), ("달", "닭"),
        ("고양이", "가"), ("각시", "ㄳ"), ("값", "갓"), ("닮다", "닭")
    ])
    func test이어쓴단어가아니면_완성이아님(candidate: String, typedWord: String) {
        #expect(!isCompletion(candidate, of: typedWord))
    }

    // 소문자 변환 전에 거를 때 ASCII·한글 밖의 첫 글자를 버리면 안 된다
    @Test("소문자 변환으로 첫 글자가 바뀌는 후보도 완성으로 봄", arguments: [
        ("\u{212A}elvin", "k"), ("İstanbul", "i"), ("Éclair", "é")
    ])
    func test소문자변환으로첫글자가바뀌는후보도_완성으로봄(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    // "가\u{11A8}"은 "각"과 정규 등가라 앞 글자 접두어로 인정된다. 첫 스칼라만 보고 버리면 안 된다
    @Test("첫가끝 자모로 쓴 같은 글자도 앞 글자로 인정")
    func test첫가끝자모로쓴같은글자도_앞글자로인정() {
        #expect(isCompletion("가\u{11A8}나다", of: "각ㄴ"))
    }

    // 입력이 첫가끝 자모면(붙여넣은 NFD 한글) 스칼라 비교 빠른 경로를 타면 안 된다. 정규 등가로 앞 글자가 같다
    @Test("입력 앞 글자가 첫가끝 자모로 쓰여도 완성형 후보를 완성으로 봄")
    func test입력앞글자가첫가끝자모로쓰여도_완성형후보를완성으로봄() {
        #expect(isCompletion("가나다", of: "\u{1100}\u{1161}나"))
    }

    @Test("자음만 입력하면 그 자음으로 시작하는 자음 단어도 완성")
    func test자음만입력하면_그자음으로시작하는자음단어도완성() {
        #expect(isCompletion("ㅋㅋㅋ", of: "ㅋ"))
    }

    @Test("입력 단어와 같은 단어는 대소문자가 달라도 완성이 아님", arguments: [
        ("키보드", "키보드"), ("KEYBOARD", "keyboard"), ("킵\u{318D}", "킵\u{318D}")
    ])
    func test입력단어와같은단어는_대소문자가달라도_완성이아님(candidate: String, typedWord: String) {
        #expect(!isCompletion(candidate, of: typedWord))
    }

    @Test("비교할 글자가 없으면 판정하지 않음", arguments: ["", "\u{318D}", "\u{318D}\u{11A2}"])
    func test비교할글자가없으면_판정하지않음(typedWord: String) {
        #expect(PredictiveTextCompletionMatchPolicy(typedWord: typedWord) == nil)
    }

    @Test("입력 첫 글자가 대문자이면 소문자로만 저장된 후보의 첫 글자를 대문자로 보여줌", arguments: [
        ("hello", "Hel", "Hello"), ("sync", "SY", "Sync")
    ])
    func test입력첫글자가대문자이면_소문자로만저장된후보의_첫글자를대문자로보여줌(
        candidate: String,
        typedWord: String,
        expected: String
    ) {
        #expect(PredictiveTextCompletionMatchPolicy(typedWord: typedWord)?.displayText(for: candidate) == expected)
    }

    // 대소문자가 섞인 표기는 사용자가 학습시킨 고유 표기라 바꾸지 않는다
    @Test("입력이 소문자이거나 후보에 대문자가 있으면 저장된 표기 그대로 보여줌", arguments: [
        ("hello", "hel", "hello"), ("SY키보드", "Sy", "SY키보드"), ("iPhone", "IP", "iPhone"), ("키보드", "키", "키보드")
    ])
    func test입력이소문자이거나_후보에대문자가있으면_저장된표기그대로보여줌(
        candidate: String,
        typedWord: String,
        expected: String
    ) {
        #expect(PredictiveTextCompletionMatchPolicy(typedWord: typedWord)?.displayText(for: candidate) == expected)
    }
}

private func isCompletion(_ candidate: String, of typedWord: String) -> Bool {
    PredictiveTextCompletionMatchPolicy(typedWord: typedWord)?.isCompletion(candidate) == true
}
