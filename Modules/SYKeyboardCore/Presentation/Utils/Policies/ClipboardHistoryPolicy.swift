//
//  ClipboardHistoryPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/8/26.
//

import Foundation

/// 클립보드 기록 한 항목
struct ClipboardHistoryItem: Codable, Equatable {
    let text: String
    let createdAt: Date

    init(text: String, createdAt: Date) {
        self.text = text
        self.createdAt = createdAt
    }
}

/// 클립보드 기록의 저장 규칙(중복 제거·개수·길이 제한)
enum ClipboardHistoryPolicy {
    /// 보관하는 최대 항목 수
    static let maxItemCount = 20
    /// 항목 하나의 최대 문자 수. 초과하면 잘라 저장하지 않고 버린다.
    /// 잘라서 저장하면 붙여넣기 결과가 원본과 달라진다
    static let maxTextLength = 2_000

    /// `text`를 기록 맨 앞에 넣은 결과. 저장하지 않을 텍스트면 `nil`
    ///
    /// - 빈 문자열, 공백·개행만 있는 문자열, `maxTextLength` 초과는 `nil`
    /// - 같은 텍스트가 있으면 제거한 뒤 맨 앞에 넣는다
    /// - `maxItemCount`를 넘는 항목은 뒤에서 버린다
    static func inserting(
        _ text: String,
        into items: [ClipboardHistoryItem],
        now: Date
    ) -> [ClipboardHistoryItem]? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= maxTextLength else { return nil }

        var result = items.filter { $0.text != text }
        result.insert(ClipboardHistoryItem(text: text, createdAt: now), at: 0)
        return Array(result.prefix(maxItemCount))
    }
}
