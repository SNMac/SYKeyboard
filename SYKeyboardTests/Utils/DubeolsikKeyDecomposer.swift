//
//  DubeolsikKeyDecomposer.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

/// 완성형 한글 한 글자를 두벌식 키 입력 순서로 분해한다.
///
/// 기대 입력을 production 테이블에서 되읽지 않도록 자모 테이블을 테스트 쪽에 따로 둔다
enum DubeolsikKeyDecomposer {
    private static let 초성Table = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    private static let 중성Table = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
    private static let 종성Table = [" ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]

    private static let 겹모음조합Table: [(앞모음: String, 뒷모음: String, 겹모음: String)] = [
        ("ㅗ", "ㅏ", "ㅘ"), ("ㅘ", "ㅣ", "ㅙ"), ("ㅗ", "ㅐ", "ㅙ"), ("ㅗ", "ㅣ", "ㅚ"),
        ("ㅜ", "ㅓ", "ㅝ"), ("ㅜ", "ㅔ", "ㅞ"), ("ㅝ", "ㅣ", "ㅞ"), ("ㅜ", "ㅣ", "ㅟ"), ("ㅡ", "ㅣ", "ㅢ")
    ]

    private static let 겹자음조합Table: [(앞자음: String, 뒷자음: String, 겹자음: String)] = [
        ("ㄱ", "ㅅ", "ㄳ"), ("ㄴ", "ㅈ", "ㄵ"), ("ㄴ", "ㅎ", "ㄶ"), ("ㄹ", "ㄱ", "ㄺ"),
        ("ㄹ", "ㅁ", "ㄻ"), ("ㄹ", "ㅂ", "ㄼ"), ("ㄹ", "ㅅ", "ㄽ"), ("ㄹ", "ㅌ", "ㄾ"),
        ("ㄹ", "ㅍ", "ㄿ"), ("ㄹ", "ㅎ", "ㅀ"), ("ㅂ", "ㅅ", "ㅄ")
    ]

    static func keys(for 한글: Character) -> [String] {
        guard let scalar = 한글.unicodeScalars.first else { return [] }
        let value = Int(scalar.value) - 0xAC00

        let 초성Index = value / (21 * 28)
        let 중성Index = (value % (21 * 28)) / 28
        let 종성Index = value % 28

        var keys = [초성Table[초성Index]]
        // 중성은 재귀로 분해한다 (ㅙ -> ㅘ+ㅣ -> ㅗ+ㅏ+ㅣ)
        keys.append(contentsOf: decompose모음(중성Table[중성Index]))
        // 겹받침은 한 번만 쪼개면 된다
        if 종성Index != 0 {
            keys.append(contentsOf: decompose자음(종성Table[종성Index]))
        }
        return keys
    }

    private static func decompose모음(_ 모음: String) -> [String] {
        if ["ㅐ", "ㅔ", "ㅒ", "ㅖ"].contains(모음) { return [모음] }

        if let match = 겹모음조합Table.first(where: { $0.겹모음 == 모음 }) {
            return decompose모음(match.앞모음) + decompose모음(match.뒷모음)
        } else {
            return [모음]
        }
    }

    private static func decompose자음(_ 자음: String) -> [String] {
        if let match = 겹자음조합Table.first(where: { $0.겹자음 == 자음 }) {
            return [match.앞자음, match.뒷자음]
        } else {
            return [자음]
        }
    }
}
