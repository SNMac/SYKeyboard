//
//  ClipboardHistoryStore.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/8/26.
//

import Foundation
import OSLog

/// 클립보드 텍스트 기록을 App Group 컨테이너의 plist 파일에 저장하는 저장소
///
/// 메모리 캐시 없이 매 연산마다 파일을 읽고 쓴다. 세 keyboard extension이 같은 파일을
/// 공유하므로 캐시가 있으면 다른 extension이 바꾼 내용을 놓친다. 최대 20개 × 2,000자라
/// 메인 스레드 동기 처리로 충분하다.
// ponytail: 매 연산 파일 I/O. 항목 수·길이 한도를 올리면 캐시 + 백그라운드 저장으로 전환
public final class ClipboardHistoryStore {

    // MARK: - Properties

    private let fileURL: URL
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "ClipboardHistoryStore"
    )

    // MARK: - Initializer

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// App Group 컨테이너를 얻지 못하면 `nil`. 호출 측은 기능을 비활성 상태로 둔다
    public convenience init?() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: DefaultValues.groupBundleID
        ) else { return nil }
        self.init(fileURL: containerURL.appendingPathComponent("clipboard_history.plist"))
    }

    // MARK: - Public Methods

    /// 저장된 기록(최신순). 파일이 없거나 손상됐으면 빈 배열
    ///
    /// 텍스트는 정책상 유일해야 하며 패널과 앱 목록이 이를 식별자로 쓴다. 손상된 파일에 중복이 있어도 첫 항목만 남긴다
    public func load() -> [ClipboardHistoryItem] {
        guard let data = try? Data(contentsOf: fileURL),
              let items = try? PropertyListDecoder().decode([ClipboardHistoryItem].self, from: data) else { return [] }
        var seen = Set<String>()
        return items.filter { seen.insert($0.text).inserted }
    }

    /// `text`를 기록 맨 앞에 저장한다. 정책상 저장 대상이 아니면 아무것도 하지 않는다
    public func record(_ text: String, now: Date = Date()) {
        guard let items = ClipboardHistoryPolicy.inserting(text, into: load(), now: now) else { return }
        save(items)
    }

    /// 사용자가 직접 입력한 `text`를 고정 항목으로 저장한다. 정책상 저장 대상이 아니면 아무것도 하지 않는다
    public func recordPinned(_ text: String, now: Date = Date()) {
        guard let items = ClipboardHistoryPolicy.insertingPinned(text, into: load(), now: now) else { return }
        save(items)
    }

    /// 지정한 인덱스 항목의 고정을 토글한다. 범위 밖이거나 고정 한도에 걸리면 아무것도 하지 않는다
    public func togglePin(at index: Int, now: Date = Date()) {
        guard let items = ClipboardHistoryPolicy.togglingPin(at: index, in: load(), now: now) else { return }
        save(items)
    }

    /// 항목의 내용을 바꾼다. 정책상 바꿀 수 없으면 아무것도 하지 않는다
    public func replaceText(_ oldText: String, with newText: String) {
        guard let items = ClipboardHistoryPolicy.replacingText(oldText, with: newText, in: load()) else { return }
        save(items)
    }

    /// 선택한 텍스트의 항목을 한 번에 고정/해제한다. 정책이 허용하지 않으면 아무것도 하지 않는다
    public func togglePins(selectedTexts: Set<String>, now: Date = Date()) {
        guard let items = ClipboardHistoryPolicy.togglingPins(selectedTexts: selectedTexts, in: load(), now: now) else { return }
        save(items)
    }

    /// 지정한 인덱스의 항목을 삭제한다. 범위 밖 인덱스는 무시한다
    public func remove(at indices: [Int]) {
        let removing = Set(indices)
        let remaining = load().enumerated()
            .filter { !removing.contains($0.offset) }
            .map(\.element)
        save(remaining)
    }

    public func removeAll() {
        save([])
    }
}

// MARK: - Private Methods

private extension ClipboardHistoryStore {
    func save(_ items: [ClipboardHistoryItem]) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // 쓰기 실패는 무시하고 다음 기회에 다시 쓴다. changeCount는 이미 갱신됐으므로 같은 텍스트를 재시도하지 않는다
            logger.error("클립보드 기록 저장 실패: \(error.localizedDescription)")
        }
    }
}
