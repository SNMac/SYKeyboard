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
    /// 고정한 시각. `nil`이면 미고정. 이 키가 없는 기존 파일은 미고정으로 읽힌다
    let pinnedAt: Date?

    var isPinned: Bool { pinnedAt != nil }

    init(text: String, createdAt: Date, pinnedAt: Date? = nil) {
        self.text = text
        self.createdAt = createdAt
        self.pinnedAt = pinnedAt
    }
}

/// 클립보드 기록의 저장 규칙(중복 제거·개수·길이 제한·고정)
///
/// 배열 순서가 곧 표시 순서다. 고정 항목이 고정 시각 최신순으로 앞에, 미고정 항목이 복사 시각 최신순으로 뒤에 온다.
enum ClipboardHistoryPolicy {
    /// 보관하는 최대 미고정 항목 수. 고정 항목은 자동으로 정리하지 않는다
    static let maxItemCount = 20
    /// 고정할 수 있는 최대 항목 수. 꽉 차면 해제 전까지 더 고정할 수 없다
    static let maxPinnedCount = 20
    /// 항목 하나의 최대 문자 수. 초과하면 잘라 저장하지 않고 버린다.
    /// 잘라서 저장하면 붙여넣기 결과가 원본과 달라진다
    static let maxTextLength = 2_000

    /// `text`를 미고정 기록 맨 앞에 넣은 결과. 저장하지 않을 텍스트면 `nil`
    ///
    /// - 빈 문자열, 공백·개행만 있는 문자열, `maxTextLength` 초과는 `nil`
    /// - 고정 항목과 같은 텍스트면 고정을 유지하고 `nil`
    /// - 미고정에 같은 텍스트가 있으면 제거한 뒤 맨 앞에 넣는다
    /// - 미고정이 `maxItemCount`를 넘으면 뒤에서 버린다
    static func inserting(
        _ text: String,
        into items: [ClipboardHistoryItem],
        now: Date
    ) -> [ClipboardHistoryItem]? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= maxTextLength,
              !items.contains(where: { $0.isPinned && $0.text == text }) else { return nil }

        let pinned = items.filter(\.isPinned)
        var unpinned = items.filter { !$0.isPinned && $0.text != text }
        unpinned.insert(ClipboardHistoryItem(text: text, createdAt: now), at: 0)
        return sorted(pinned + unpinned.prefix(maxItemCount))
    }

    /// 고정 한도에 여유가 있는지
    static func canPin(_ items: [ClipboardHistoryItem]) -> Bool {
        return items.filter(\.isPinned).count < maxPinnedCount
    }

    /// `index` 항목의 고정을 토글하고 정렬한 결과. 범위 밖이거나 고정 한도에 걸리면 `nil`
    ///
    /// 해제한 항목은 원래 복사 시각 순서의 미고정 자리로 돌아간다
    static func togglingPin(
        at index: Int,
        in items: [ClipboardHistoryItem],
        now: Date
    ) -> [ClipboardHistoryItem]? {
        guard items.indices.contains(index) else { return nil }
        let target = items[index]
        guard target.isPinned || canPin(items) else { return nil }

        var result = items
        result[index] = ClipboardHistoryItem(
            text: target.text,
            createdAt: target.createdAt,
            pinnedAt: target.isPinned ? nil : now
        )
        return sorted(result)
    }

    /// 고정은 고정 시각 최신순으로 앞에, 미고정은 복사 시각 최신순으로 뒤에
    static func sorted(_ items: [ClipboardHistoryItem]) -> [ClipboardHistoryItem] {
        let pinned = items.filter(\.isPinned)
            .sorted { ($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast) }
        let unpinned = items.filter { !$0.isPinned }
            .sorted { $0.createdAt > $1.createdAt }
        return pinned + unpinned
    }
}
