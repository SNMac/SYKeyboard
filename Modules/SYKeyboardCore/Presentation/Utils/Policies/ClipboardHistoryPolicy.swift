//
//  ClipboardHistoryPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/8/26.
//

import Foundation

/// 클립보드 기록 한 항목
public struct ClipboardHistoryItem: Codable, Equatable, Identifiable {
    /// 정책이 텍스트 중복을 허용하지 않으므로 텍스트가 곧 식별자다
    public var id: String { text }

    public let text: String
    public let createdAt: Date
    /// 고정한 시각. `nil`이면 미고정. 이 키가 없는 기존 파일은 미고정으로 읽힌다
    public let pinnedAt: Date?

    public var isPinned: Bool { pinnedAt != nil }

    public init(text: String, createdAt: Date, pinnedAt: Date? = nil) {
        self.text = text
        self.createdAt = createdAt
        self.pinnedAt = pinnedAt
    }
}

/// 클립보드 기록의 저장 규칙(중복 제거·개수·길이 제한·고정)
///
/// 배열 순서가 곧 표시 순서다. 고정 항목이 고정 시각 최신순으로 앞에, 미고정 항목이 복사 시각 최신순으로 뒤에 온다.
public enum ClipboardHistoryPolicy {
    /// 보관하는 최대 미고정 항목 수. 고정 항목은 자동으로 정리하지 않는다
    public static let maxItemCount = 20
    /// 고정할 수 있는 최대 항목 수. 꽉 차면 해제 전까지 더 고정할 수 없다
    public static let maxPinnedCount = 20
    /// 항목 하나의 최대 문자 수. 초과하면 잘라 저장하지 않고 버린다.
    /// 잘라서 저장하면 붙여넣기 결과가 원본과 달라진다
    public static let maxTextLength = 2_000

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
        let unpinned = items.filter { !$0.isPinned && $0.text != text }
            + [ClipboardHistoryItem(text: text, createdAt: now)]
        // 입력 순서에 기대지 않도록 정렬한 뒤 오래된 미고정 항목을 버린다
        let trimmedUnpinned = sorted(unpinned).prefix(maxItemCount)
        return sorted(pinned + trimmedUnpinned)
    }

    /// 사용자가 직접 입력한 `text`를 고정 항목으로 맨 앞에 넣은 결과. 저장하지 않을 텍스트면 `nil`
    ///
    /// - 빈 문자열, 공백·개행만 있는 문자열, `maxTextLength` 초과, 고정 한도 초과는 `nil`
    /// - 같은 텍스트가 이미 고정이면 `nil`, 미고정이면 그 항목을 제거하고 고정으로 대체한다
    static func insertingPinned(
        _ text: String,
        into items: [ClipboardHistoryItem],
        now: Date
    ) -> [ClipboardHistoryItem]? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= maxTextLength,
              canPin(items),
              !items.contains(where: { $0.isPinned && $0.text == text }) else { return nil }

        let remaining = items.filter { $0.text != text }
        return sorted(remaining + [ClipboardHistoryItem(text: text, createdAt: now, pinnedAt: now)])
    }

    /// 텍스트 전체가 http/https URL 하나일 때 그 URL. 앞뒤 공백·개행은 무시하고, 중간에 공백이 있으면 `nil`
    public static func openableURL(in text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    /// 고정 한도에 여유가 있는지
    public static func canPin(_ items: [ClipboardHistoryItem]) -> Bool {
        return items.filter(\.isPinned).count < maxPinnedCount
    }

    /// `index` 항목의 고정을 토글하고 정렬한 결과. 범위 밖이거나 고정 한도에 걸리면 `nil`
    ///
    /// 해제한 항목은 원래 복사 시각 순서의 미고정 자리로 돌아간다. 이때 미고정이 잠시 `maxItemCount`를
    /// 넘을 수 있으며 다음 `inserting`에서 정리된다
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

    /// 편집 모드에서 선택한 항목을 한 번에 고정/해제할 때의 대상과 허용 여부
    public struct PinBatch: Equatable {
        /// 바뀔 항목. 목록 순서를 유지한다
        public let targets: [ClipboardHistoryItem]
        /// 선택이 전부 고정이면 모두 해제, 아니면 미고정만 고정한다
        public let isUnpinning: Bool
        /// 대상이 있고, 고정이라면 고정 한도를 넘지 않는지
        public let isAllowed: Bool
    }

    /// `selectedTexts`에 해당하는 항목의 일괄 고정/해제 계획
    public static func pinBatch(
        selectedTexts: Set<String>,
        in items: [ClipboardHistoryItem]
    ) -> PinBatch {
        let selected = items.filter { selectedTexts.contains($0.text) }
        let isUnpinning = !selected.isEmpty && selected.allSatisfy(\.isPinned)
        let targets = isUnpinning ? selected : selected.filter { !$0.isPinned }
        let pinnedCount = items.filter(\.isPinned).count
        let isAllowed = !targets.isEmpty
            && (isUnpinning || pinnedCount + targets.count <= maxPinnedCount)
        return PinBatch(targets: targets, isUnpinning: isUnpinning, isAllowed: isAllowed)
    }

    /// `pinBatch`를 적용하고 정렬한 결과. 허용되지 않으면 `nil`
    ///
    /// 고정 시각은 목록 순서대로 1ms씩 앞당겨, 함께 고정한 항목이 목록에서 보던 순서 그대로 위에 온다
    static func togglingPins(
        selectedTexts: Set<String>,
        in items: [ClipboardHistoryItem],
        now: Date
    ) -> [ClipboardHistoryItem]? {
        let batch = pinBatch(selectedTexts: selectedTexts, in: items)
        guard batch.isAllowed else { return nil }

        let targetTexts = batch.targets.map(\.text)
        let result = items.map { item -> ClipboardHistoryItem in
            guard let offset = targetTexts.firstIndex(of: item.text) else { return item }
            return ClipboardHistoryItem(
                text: item.text,
                createdAt: item.createdAt,
                pinnedAt: batch.isUnpinning ? nil : now.addingTimeInterval(-Double(offset) / 1_000)
            )
        }
        return sorted(result)
    }

    /// 고정은 고정 시각 최신순으로 앞에, 미고정은 복사 시각 최신순으로 뒤에. 시각이 같으면 텍스트 순으로 고정한다
    static func sorted(_ items: [ClipboardHistoryItem]) -> [ClipboardHistoryItem] {
        let pinned = items.filter(\.isPinned).sorted { lhs, rhs in
            let lhsDate = lhs.pinnedAt ?? .distantPast
            let rhsDate = rhs.pinnedAt ?? .distantPast
            return lhsDate != rhsDate ? lhsDate > rhsDate : lhs.text < rhs.text
        }
        let unpinned = items.filter { !$0.isPinned }.sorted { lhs, rhs in
            lhs.createdAt != rhs.createdAt ? lhs.createdAt > rhs.createdAt : lhs.text < rhs.text
        }
        return pinned + unpinned
    }
}
