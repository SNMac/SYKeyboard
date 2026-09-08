//
//  ClipboardHistoryPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/8/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 기록 저장 정책 검증")
struct ClipboardHistoryPolicyTests {

    private let now = Date(timeIntervalSince1970: 1_000)

    @Test("빈 문자열과 공백·개행만 있는 문자열은 저장하지 않음")
    func test빈문자열과공백은_저장하지않음() {
        #expect(ClipboardHistoryPolicy.inserting("", into: [], now: now) == nil)
        #expect(ClipboardHistoryPolicy.inserting(" \n\t", into: [], now: now) == nil)
    }

    @Test("최대 길이까지는 저장하고 넘으면 잘라 저장하지 않고 버림")
    func test최대길이초과는_버림() {
        let limit = String(repeating: "가", count: ClipboardHistoryPolicy.maxTextLength)
        let over = limit + "나"

        #expect(ClipboardHistoryPolicy.inserting(limit, into: [], now: now)?.first?.text == limit)
        #expect(ClipboardHistoryPolicy.inserting(over, into: [], now: now) == nil)
    }

    @Test("새 텍스트는 맨 앞에 들어가고 기존 순서는 유지")
    func test새텍스트는_맨앞에삽입() {
        let items = [item("a"), item("b")]

        let result = ClipboardHistoryPolicy.inserting("c", into: items, now: now)

        #expect(result?.map(\.text) == ["c", "a", "b"])
        #expect(result?.first?.createdAt == now)
    }

    @Test("같은 텍스트는 중복 저장하지 않고 맨 앞으로 이동")
    func test중복텍스트는_맨앞으로이동() {
        let items = [item("a"), item("b"), item("c")]

        let result = ClipboardHistoryPolicy.inserting("b", into: items, now: now)

        #expect(result?.map(\.text) == ["b", "a", "c"])
    }

    @Test("최대 개수를 넘으면 가장 오래된 항목을 버림")
    func test최대개수초과시_가장오래된항목제거() {
        let items = (0..<ClipboardHistoryPolicy.maxItemCount).map { item("\($0)") }

        let result = ClipboardHistoryPolicy.inserting("new", into: items, now: now)

        #expect(result?.count == ClipboardHistoryPolicy.maxItemCount)
        #expect(result?.first?.text == "new")
        #expect(result?.last?.text == "\(ClipboardHistoryPolicy.maxItemCount - 2)")
    }

    @Test("고정하면 고정 시각 최신순으로 맨 앞에 오고 미고정은 그 뒤에 최신순")
    func test고정하면_최근고정순으로_맨앞() {
        let items = [item("a", createdAt: 3), item("b", createdAt: 2), item("c", createdAt: 1)]

        let first = ClipboardHistoryPolicy.togglingPin(at: 2, in: items, now: Date(timeIntervalSince1970: 10))
        #expect(first?.map(\.text) == ["c", "a", "b"])
        #expect(first?[0].isPinned == true)

        let second = ClipboardHistoryPolicy.togglingPin(at: 2, in: first ?? [], now: Date(timeIntervalSince1970: 11))
        #expect(second?.map(\.text) == ["b", "c", "a"])
        #expect(second?.map(\.isPinned) == [true, true, false])
    }

    @Test("고정을 해제하면 복사 시각 순서의 미고정 자리로 돌아감")
    func test고정해제하면_복사시각순서로복귀() {
        let items = [
            item("b", createdAt: 2, pinnedAt: 11),
            item("c", createdAt: 1, pinnedAt: 10),
            item("a", createdAt: 3)
        ]

        let result = ClipboardHistoryPolicy.togglingPin(at: 0, in: items, now: Date(timeIntervalSince1970: 12))

        #expect(result?.map(\.text) == ["c", "a", "b"])
        #expect(result?.map(\.isPinned) == [true, false, false])
    }

    @Test("새 텍스트는 고정 항목 뒤에 들어가고 자동 정리는 미고정 항목만 셈")
    func test새텍스트는_고정뒤에_삽입되고_미고정만정리() {
        let pinned = item("p", createdAt: 0, pinnedAt: 100)
        let unpinned = (0..<ClipboardHistoryPolicy.maxItemCount).map {
            item("\($0)", createdAt: TimeInterval(ClipboardHistoryPolicy.maxItemCount - $0))
        }

        let result = ClipboardHistoryPolicy.inserting("new", into: [pinned] + unpinned, now: Date(timeIntervalSince1970: 1_000))

        #expect(result?.count == ClipboardHistoryPolicy.maxItemCount + 1)
        #expect(result?[0].text == "p")
        #expect(result?[1].text == "new")
        #expect(result?.last?.text == "\(ClipboardHistoryPolicy.maxItemCount - 2)")
    }

    @Test("고정된 텍스트를 다시 복사하면 아무것도 바꾸지 않음")
    func test고정텍스트재복사는_변경없음() {
        let items = [item("p", createdAt: 0, pinnedAt: 100), item("a", createdAt: 1)]

        #expect(ClipboardHistoryPolicy.inserting("p", into: items, now: now) == nil)
    }

    @Test("미고정 중복 텍스트는 고정 항목 뒤 맨 앞으로 이동")
    func test미고정중복은_고정뒤맨앞으로이동() {
        let items = [item("p", createdAt: 0, pinnedAt: 100), item("a", createdAt: 2), item("b", createdAt: 1)]

        let result = ClipboardHistoryPolicy.inserting("b", into: items, now: Date(timeIntervalSince1970: 3))

        #expect(result?.map(\.text) == ["p", "b", "a"])
    }

    @Test("고정 한도가 차면 더 고정할 수 없고 해제는 가능")
    func test고정한도차면_고정불가_해제가능() {
        let pinned = (0..<ClipboardHistoryPolicy.maxPinnedCount).map {
            item("p\($0)", createdAt: 0, pinnedAt: TimeInterval(100 + $0))
        }
        let items = pinned + [item("a", createdAt: 1)]

        #expect(ClipboardHistoryPolicy.canPin(items) == false)
        #expect(ClipboardHistoryPolicy.togglingPin(at: items.count - 1, in: items, now: now) == nil)
        #expect(ClipboardHistoryPolicy.togglingPin(at: 0, in: items, now: now)?.filter(\.isPinned).count == ClipboardHistoryPolicy.maxPinnedCount - 1)
    }

    @Test("범위 밖 인덱스의 고정 토글은 nil")
    func test범위밖인덱스_고정토글은_nil() {
        #expect(ClipboardHistoryPolicy.togglingPin(at: 5, in: [item("a")], now: now) == nil)
    }

    private func item(
        _ text: String,
        createdAt: TimeInterval = 0,
        pinnedAt: TimeInterval? = nil
    ) -> ClipboardHistoryItem {
        ClipboardHistoryItem(
            text: text,
            createdAt: Date(timeIntervalSince1970: createdAt),
            pinnedAt: pinnedAt.map { Date(timeIntervalSince1970: $0) }
        )
    }
}
