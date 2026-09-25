//
//  PredictiveTextScriptPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/25/26.
//

import Foundation

/// NGram 후보 단어의 문자 종류
enum PredictiveTextScript: Hashable {
    case hangeul
    case latin
    case other
}

/// 한영 통합 NGram에서 unigram 후보를 현재 언어 모드 순으로 세우기 위한 문자 종류 판별
enum PredictiveTextScriptPolicy {

    /// 한글이 하나라도 있으면 한글, 아니고 라틴 문자가 있으면 라틴, 둘 다 없으면 기타로 본다.
    /// 'SY키보드'처럼 섞인 단어는 한글이다
    static func script(of word: String) -> PredictiveTextScript {
        var hasLatin = false
        for scalar in word.unicodeScalars {
            if isHangeul(scalar) { return .hangeul }
            if isLatinLetter(scalar) { hasLatin = true }
        }
        return hasLatin ? .latin : .other
    }

    /// 언어 모드 식별자에서 먼저 보여줄 문자 종류를 정한다. 모르는 식별자는 `nil`이다
    static func preferredScript(forLanguage language: String) -> PredictiveTextScript? {
        switch language {
        case "ko-KR":
            return .hangeul
        case "en-US":
            return .latin
        default:
            return nil
        }
    }

    private static func isHangeul(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0xAC00...0xD7A3, // 음절
             0x1100...0x11FF, // 자모
             0x3130...0x318F, // 호환 자모
             0xA960...0xA97F, // 자모 확장 A
             0xD7B0...0xD7FF: // 자모 확장 B
            return true
        default:
            return false
        }
    }

    private static func isLatinLetter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x41...0x5A, 0x61...0x7A:
            return true
        case 0xC0...0x24F:
            // Latin-1 보충·확장 A/B의 문자만. `×`, `÷`는 기호라 빠진다
            return scalar.properties.isAlphabetic
        default:
            return false
        }
    }
}
