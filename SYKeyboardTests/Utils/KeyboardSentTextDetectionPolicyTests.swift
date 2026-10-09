//
//  KeyboardSentTextDetectionPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/28/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("전송 판정 정책 검증")
struct KeyboardSentTextDetectionPolicyTests {

    private static let document = UUID()
    private static let otherDocument = UUID()

    struct Case: CustomTestStringConvertible {
        let name: String
        let before: UUID?
        let after: UUID?
        var beforeInput: String? = nil
        var afterInput: String? = nil
        var selectedText: String? = nil
        var returnKeyType: UIReturnKeyType? = .default
        let isSent: Bool

        var testDescription: String { name }
    }

    private static let cases: [Case] = [
        Case(name: "같은 입력창이 완전히 비면 전송", before: document, after: document, isSent: true),
        Case(name: "빈 문자열 문맥과 선택도 빈 것으로 봄",
             before: document, after: document, beforeInput: "", afterInput: "", selectedText: "", isSent: true),
        // 다른 입력창으로 옮기거나 키보드를 내릴 때 관찰한 값
        Case(name: "바뀐 뒤 식별자가 nil이면 전송이 아님", before: document, after: nil, isSent: false),
        Case(name: "다른 입력창으로 바뀌면 전송이 아님", before: document, after: otherDocument, isSent: false),
        Case(name: "바뀌기 전 식별자가 nil이면 전송이 아님", before: nil, after: document, isSent: false),
        Case(name: "양쪽 식별자가 모두 nil이면 전송이 아님", before: nil, after: nil, isSent: false),
        Case(name: "앞 문맥이 남으면 전송이 아님", before: document, after: document, beforeInput: "ㅇㅇ", isSent: false),
        // 전체 선택 첫 단계: 커서가 앞으로 가며 뒤 문맥에 텍스트가 남는다
        Case(name: "뒤 문맥이 남으면 전송이 아님", before: document, after: document, afterInput: "전체", isSent: false),
        Case(name: "선택 텍스트가 남으면 전송이 아님", before: document, after: document, selectedText: "전체", isSent: false),
        // 검색창의 지우기(X) 버튼도 같은 입력창을 비우므로 전송과 구분할 수 없다
        Case(name: "리턴 키가 검색인 입력창은 비어도 전송이 아님",
             before: document, after: document, returnKeyType: .search, isSent: false),
        Case(name: "리턴 키 종류를 알 수 없어도 나머지 조건으로 판정",
             before: document, after: document, returnKeyType: nil, isSent: true)
    ]

    @Test("같은 입력창이 완전히 비고 리턴 키가 검색이 아닐 때만 전송으로 판정",
          arguments: KeyboardSentTextDetectionPolicyTests.cases)
    func test전송판정(_ testCase: Case) {
        #expect(
            KeyboardSentTextDetectionPolicy.isSentAfterTextChange(
                documentIdentifierBeforeChange: testCase.before,
                documentIdentifierAfterChange: testCase.after,
                beforeInput: testCase.beforeInput,
                afterInput: testCase.afterInput,
                selectedText: testCase.selectedText,
                returnKeyType: testCase.returnKeyType
            ) == testCase.isSent
        )
    }
}
