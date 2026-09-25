//
//  PredictiveTextCompletionMatchPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/25/26.
//

import Foundation

/// 입력 중인 단어를 이어 쓴 NGram 학습 단어인지 판정하는 접두어 규칙
///
/// 대소문자를 무시하고, 아직 조합 중일 수 있는 마지막 글자만 호환 자모 단위로 비교한다.
/// `"키볻"`의 받침 ㄷ은 `"키보드"`의 다음 초성으로, `"닭"`의 겹받침 ㄺ은 `"달걀"`의 ㄹ 받침과 ㄱ 초성으로 본다.
/// 모음 합성(ㅘ, ㅐ)과 쌍자음은 나누지 않는다. 합성 전 상태에서는 목표 단어가 아직 보이지 않았으므로
/// 나누면 두벌식에서 '가'에 '개발'이 뜨는 잡음만 생긴다
struct PredictiveTextCompletionMatchPolicy {

    // MARK: - Properties

    /// 무엇이 될지 아직 모르는 천지인 조합 중 모음(ㆍ, ᆢ). 입력 끝에 있으면 떼고 비교한다.
    /// ᆢ(U+11A2)는 앞 완성형 글자와 한 `Character`로 묶일 수 있어 스칼라 단위로 뗀다
    private static let cheonjiinPendingVowels: Set<Unicode.Scalar> = ["\u{318D}", "\u{11A2}"]
    private static let choseongTable = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ".unicodeScalars)
    private static let jungseongTable = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ".unicodeScalars)
    /// 받침 없음을 뺀 종성 27개
    private static let jongseongTable = Array("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ".unicodeScalars)
    /// 겹받침 → 두 자음
    private static let compoundConsonants: [Unicode.Scalar: [Unicode.Scalar]] = [
        "ㄳ": ["ㄱ", "ㅅ"], "ㄵ": ["ㄴ", "ㅈ"], "ㄶ": ["ㄴ", "ㅎ"], "ㄺ": ["ㄹ", "ㄱ"],
        "ㄻ": ["ㄹ", "ㅁ"], "ㄼ": ["ㄹ", "ㅂ"], "ㄽ": ["ㄹ", "ㅅ"], "ㄾ": ["ㄹ", "ㅌ"],
        "ㄿ": ["ㄹ", "ㅍ"], "ㅀ": ["ㄹ", "ㅎ"], "ㅄ": ["ㅂ", "ㅅ"]
    ]

    /// 소문자로 바꾼 입력 단어. 같은 단어는 0번 칸이 보여주므로 완성으로 보지 않는다
    private let loweredTypedWord: String
    /// 마지막 글자를 뺀 입력. 후보가 이 문자열로 시작해야 한다
    private let head: String
    /// 마지막 글자의 호환 자모
    private let lastJamo: [Unicode.Scalar]

    // MARK: - Initializer

    /// 비교할 글자가 없으면(빈 문자열, 천지인 조합 중 모음뿐) `nil`이다
    init?(typedWord: String) {
        let lowered = typedWord.lowercased()
        var scalars = lowered.unicodeScalars
        while let last = scalars.last, Self.cheonjiinPendingVowels.contains(last) {
            scalars.removeLast()
        }
        let typed = String(scalars)
        guard let last = typed.last else { return nil }

        loweredTypedWord = lowered
        head = String(typed.dropLast())
        lastJamo = Self.jamo(of: last)
    }

    // MARK: - Internal Methods

    /// `candidate`가 입력 단어를 이어 쓴 단어면 `true`다
    func isCompletion(_ candidate: String) -> Bool {
        let lowered = candidate.lowercased()
        guard lowered.hasPrefix(head) else { return false }
        let rest = lowered.dropFirst(head.count)
        // 대부분은 다음 글자의 첫 자모에서 갈리므로 자모 배열을 만들기 전에 거른다
        guard let next = rest.first,
              Self.firstJamo(of: next) == lastJamo.first,
              lowered != loweredTypedWord else { return false }

        var candidateJamo: [Unicode.Scalar] = []
        // 글자마다 자모가 하나 이상이므로 마지막 글자의 자모 수만큼만 보면 충분하다
        for character in rest.prefix(lastJamo.count) {
            candidateJamo += Self.jamo(of: character)
        }
        return candidateJamo.starts(with: lastJamo)
    }
}

// MARK: - Private Methods

private extension PredictiveTextCompletionMatchPolicy {
    static func firstJamo(of character: Character) -> Unicode.Scalar? {
        guard let scalar = character.unicodeScalars.first else { return nil }
        if let consonants = compoundConsonants[scalar] { return consonants.first }
        guard let index = syllableIndex(of: scalar) else { return scalar }
        return choseongTable[index / 588]
    }

    static func jamo(of character: Character) -> [Unicode.Scalar] {
        let scalars = character.unicodeScalars
        guard scalars.count == 1, let scalar = scalars.first else { return Array(scalars) }
        if let consonants = compoundConsonants[scalar] { return consonants }
        guard let index = syllableIndex(of: scalar) else { return [scalar] }

        let syllable = [choseongTable[index / 588], jungseongTable[(index % 588) / 28]]
        let jongseongIndex = index % 28
        guard jongseongIndex > 0 else { return syllable }
        let jongseong = jongseongTable[jongseongIndex - 1]
        return syllable + (compoundConsonants[jongseong] ?? [jongseong])
    }

    /// 완성형 음절이면 `0xAC00`부터의 순번을 돌려준다
    static func syllableIndex(of scalar: Unicode.Scalar) -> Int? {
        guard (0xAC00...0xD7A3).contains(scalar.value) else { return nil }
        return Int(scalar.value - 0xAC00)
    }
}
