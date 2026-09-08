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

    private func item(_ text: String) -> ClipboardHistoryItem {
        ClipboardHistoryItem(text: text, createdAt: Date(timeIntervalSince1970: 0))
    }
}
