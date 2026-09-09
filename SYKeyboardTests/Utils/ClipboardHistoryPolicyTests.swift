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
        let items = (0..<ClipboardHistoryPolicy.maxItemCount).map {
            item("\($0)", createdAt: TimeInterval(ClipboardHistoryPolicy.maxItemCount - $0))
        }

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

    @Test("직접 추가한 텍스트는 고정 항목으로 맨 앞에 들어감")
    func test직접추가는_고정항목으로_맨앞() {
        let items = [item("p", createdAt: 0, pinnedAt: 100), item("a", createdAt: 1)]

        let result = ClipboardHistoryPolicy.insertingPinned("new", into: items, now: Date(timeIntervalSince1970: 200))

        #expect(result?.map(\.text) == ["new", "p", "a"])
        #expect(result?[0].pinnedAt == Date(timeIntervalSince1970: 200))
        #expect(result?[0].createdAt == Date(timeIntervalSince1970: 200))
    }

    @Test("직접 추가한 텍스트가 미고정에 있으면 그 항목을 고정으로 대체")
    func test직접추가가_미고정중복이면_고정으로대체() {
        let items = [item("a", createdAt: 2), item("b", createdAt: 1)]

        let result = ClipboardHistoryPolicy.insertingPinned("b", into: items, now: Date(timeIntervalSince1970: 3))

        #expect(result?.map(\.text) == ["b", "a"])
        #expect(result?.map(\.isPinned) == [true, false])
    }

    @Test("직접 추가는 빈 텍스트·이미 고정된 텍스트·고정 한도 초과면 nil")
    func test직접추가_거부조건() {
        let pinnedFull = (0..<ClipboardHistoryPolicy.maxPinnedCount).map {
            item("p\($0)", createdAt: 0, pinnedAt: TimeInterval(100 + $0))
        }

        #expect(ClipboardHistoryPolicy.insertingPinned(" \n", into: [], now: now) == nil)
        #expect(ClipboardHistoryPolicy.insertingPinned("p0", into: [item("p0", createdAt: 0, pinnedAt: 1)], now: now) == nil)
        #expect(ClipboardHistoryPolicy.insertingPinned("new", into: pinnedFull, now: now) == nil)
    }

    @Test("복사 시각이 같으면 텍스트 순으로 정렬해 순서를 고정")
    func test시각이같으면_텍스트순() {
        let items = [item("b", createdAt: 5), item("a", createdAt: 5), item("c", createdAt: 9)]

        #expect(ClipboardHistoryPolicy.sorted(items).map(\.text) == ["c", "a", "b"])
    }

    @Test("선택에 미고정이 섞이면 미고정만 고정 대상")
    func test선택에미고정이섞이면_미고정만고정대상() {
        let items = [item("p", pinnedAt: 100), item("a", createdAt: 2), item("b", createdAt: 1)]

        let batch = ClipboardHistoryPolicy.pinBatch(selectedTexts: ["p", "a", "b"], in: items)

        #expect(batch.targets.map(\.text) == ["a", "b"])
        #expect(batch.isUnpinning == false)
        #expect(batch.isAllowed)
    }

    @Test("선택이 전부 고정이면 모두 해제 대상")
    func test선택이전부고정이면_해제대상() {
        let items = [item("p1", pinnedAt: 101), item("p2", pinnedAt: 100), item("a")]

        let batch = ClipboardHistoryPolicy.pinBatch(selectedTexts: ["p1", "p2"], in: items)

        #expect(batch.targets.map(\.text) == ["p1", "p2"])
        #expect(batch.isUnpinning)
        #expect(batch.isAllowed)
    }

    @Test("선택이 없거나 목록에 없는 텍스트뿐이면 불허")
    func test선택없으면_불허() {
        let items = [item("a")]

        #expect(ClipboardHistoryPolicy.pinBatch(selectedTexts: [], in: items).isAllowed == false)
        #expect(ClipboardHistoryPolicy.pinBatch(selectedTexts: ["zzz"], in: items).isAllowed == false)
        #expect(ClipboardHistoryPolicy.togglingPins(selectedTexts: [], in: items, now: now) == nil)
    }

    @Test("일괄 고정은 현재 고정 수와 합쳐 한도까지만 허용")
    func test일괄고정은_한도경계까지허용() {
        let pinned = (0..<(ClipboardHistoryPolicy.maxPinnedCount - 1)).map {
            item("p\($0)", pinnedAt: TimeInterval(100 + $0))
        }
        let items = pinned + [item("a", createdAt: 2), item("b", createdAt: 1)]

        #expect(ClipboardHistoryPolicy.pinBatch(selectedTexts: ["a"], in: items).isAllowed)
        #expect(ClipboardHistoryPolicy.pinBatch(selectedTexts: ["a", "b"], in: items).isAllowed == false)
        #expect(ClipboardHistoryPolicy.togglingPins(selectedTexts: ["a", "b"], in: items, now: now) == nil)
    }

    @Test("함께 고정한 항목은 목록에서 보던 순서대로 위에 옴")
    func test일괄고정은_목록순서유지() {
        let items = [item("c", createdAt: 3), item("b", createdAt: 2), item("a", createdAt: 1), item("x", createdAt: 0)]

        let result = ClipboardHistoryPolicy.togglingPins(selectedTexts: ["c", "b", "a"], in: items, now: now)

        #expect(result?.map(\.text) == ["c", "b", "a", "x"])
        #expect(result?.prefix(3).allSatisfy(\.isPinned) == true)
        #expect(result?.first?.pinnedAt == now)
        #expect(result?[1].pinnedAt == now.addingTimeInterval(-0.001))
    }

    @Test("일괄 해제한 항목은 복사 시각 순서의 미고정 자리로 돌아감")
    func test일괄해제는_미고정자리로복귀() {
        let items = [item("p1", createdAt: 1, pinnedAt: 101), item("p2", createdAt: 3, pinnedAt: 100), item("a", createdAt: 2)]

        let result = ClipboardHistoryPolicy.togglingPins(selectedTexts: ["p1", "p2"], in: items, now: now)

        #expect(result?.map(\.text) == ["p2", "a", "p1"])
        #expect(result?.contains(where: \.isPinned) == false)
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
