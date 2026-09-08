//
//  LexiconPredictiveTextEngine.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit

/// `UILexicon` 기반의 자동완성 엔진
///
/// 사용자의 연락처, 텍스트 대치 항목 등 개인화된 데이터를 기반으로
/// 자동완성 후보를 제공합니다.
///
/// - Note: `UILexicon`은 키보드 익스텐션에서만 사용 가능하며,
///   `UIInputViewController.requestSupplementaryLexicon`을 통해 로드해야 합니다.
struct TextReplacementEntry: Equatable {
    let userInput: String
    let documentText: String
}

protocol LexiconSuggestionProviding: PredictiveTextProvider {
    var hasLoadedLexicon: Bool { get }
    /// 소문자로 정규화한 단어와 `userInput`이 정확히 일치하는 엔트리를 lexicon의 원래 순서대로 반환합니다.
    func textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry]
}

protocol LexiconLoadableSuggestionProviding: LexiconSuggestionProviding {
    func setLexicon(_ lexicon: UILexicon)
}

final class LexiconPredictiveTextEngine: LexiconLoadableSuggestionProviding {

    // MARK: - Properties

    private(set) var lexicon: UILexicon?
    /// `userInput.lowercased()` → 엔트리(원래 순서). 키 입력마다 전체를 순회하지 않도록 로드 시 한 번 만든다
    private var entriesByLowercasedInput: [String: [TextReplacementEntry]] = [:]

    var hasLoadedLexicon: Bool {
        lexicon != nil
    }

    // MARK: - Internal Methods

    /// `UILexicon`을 설정하고 조회 인덱스를 만듭니다.
    ///
    /// `UIInputViewController.requestSupplementaryLexicon`의 결과를 전달받아 저장합니다.
    ///
    /// - Parameter lexicon: 로드된 `UILexicon` 객체
    func setLexicon(_ lexicon: UILexicon) {
        self.lexicon = lexicon
        var index: [String: [TextReplacementEntry]] = [:]
        for entry in lexicon.entries {
            index[entry.userInput.lowercased(), default: []].append(
                TextReplacementEntry(userInput: entry.userInput, documentText: entry.documentText)
            )
        }
        entriesByLowercasedInput = index
    }

    func textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry] {
        entriesByLowercasedInput[lowercasedWord] ?? []
    }

    // MARK: - PredictiveTextService Methods

    /// 현재 입력된 단어와 정확히 일치하는 텍스트 대치 후보만 반환합니다.
    ///
    /// - Parameter baseText: 자동완성을 제공할 텍스트
    /// - Returns: 정확히 매칭된 대치 결과 배열
    func suggestions(for baseText: String) -> [String] {
        guard hasLoadedLexicon else { return [] }

        let lastWord = currentWord(from: baseText)
        guard !lastWord.isEmpty else { return [] }

        let lowered = lastWord.lowercased()

        // 이 필터는 검색어에 의존하므로 인덱스에 미리 넣지 않는다
        return textReplacementEntries(matching: lowered).compactMap { entry in
            entry.documentText.lowercased() != lowered ? entry.documentText : nil
        }
    }

    // UILexicon은 시스템이 관리하므로 학습 불필요
    func learn(word: String) {}
}

// MARK: - Private Methods

private extension LexiconPredictiveTextEngine {
    func currentWord(from text: String) -> String {
        guard let last = text.split(whereSeparator: { $0.isWhitespace }).last else {
            return ""
        }
        return String(last)
    }
}
