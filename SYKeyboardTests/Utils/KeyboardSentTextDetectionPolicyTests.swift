//
//  KeyboardSentTextDetectionPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/28/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("전송 판정 정책 검증")
struct KeyboardSentTextDetectionPolicyTests {

    private let document = UUID()

    @Test("같은 입력창이 완전히 비면 전송으로 판정")
    func test같은입력창이완전히비면_전송으로판정() {
        #expect(isSent(before: document, after: document, beforeInput: nil, afterInput: nil, selectedText: nil))
    }

    @Test("빈 문자열 문맥과 선택도 빈 것으로 봄")
    func test빈문자열문맥과선택도_빈것으로봄() {
        #expect(isSent(before: document, after: document, beforeInput: "", afterInput: "", selectedText: ""))
    }

    @Test("바뀐 뒤 식별자가 nil이면 전송이 아님")
    func test바뀐뒤식별자가nil이면_전송이아님() {
        // 다른 입력창으로 옮기거나 키보드를 내릴 때 관찰한 값
        #expect(!isSent(before: document, after: nil, beforeInput: nil, afterInput: nil, selectedText: nil))
    }

    @Test("다른 입력창으로 바뀌면 전송이 아님")
    func test다른입력창으로바뀌면_전송이아님() {
        #expect(!isSent(before: document, after: UUID(), beforeInput: nil, afterInput: nil, selectedText: nil))
    }

    @Test("바뀌기 전 식별자가 nil이면 전송이 아님")
    func test바뀌기전식별자가nil이면_전송이아님() {
        #expect(!isSent(before: nil, after: document, beforeInput: nil, afterInput: nil, selectedText: nil))
        #expect(!isSent(before: nil, after: nil, beforeInput: nil, afterInput: nil, selectedText: nil))
    }

    @Test("앞 문맥, 뒤 문맥, 선택 텍스트 중 하나라도 남으면 전송이 아님")
    func test문맥이나선택이남으면_전송이아님() {
        #expect(!isSent(before: document, after: document, beforeInput: "ㅇㅇ", afterInput: nil, selectedText: nil))
        // 전체 선택 첫 단계: 커서가 앞으로 가며 뒤 문맥에 텍스트가 남는다
        #expect(!isSent(before: document, after: document, beforeInput: nil, afterInput: "전체", selectedText: nil))
        #expect(!isSent(before: document, after: document, beforeInput: nil, afterInput: nil, selectedText: "전체"))
    }

    private func isSent(
        before: UUID?,
        after: UUID?,
        beforeInput: String?,
        afterInput: String?,
        selectedText: String?
    ) -> Bool {
        KeyboardSentTextDetectionPolicy.isSentAfterTextChange(
            documentIdentifierBeforeChange: before,
            documentIdentifierAfterChange: after,
            beforeInput: beforeInput,
            afterInput: afterInput,
            selectedText: selectedText
        )
    }
}
