//
//  KeyboardTextInteractionPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/1/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("키보드 텍스트 상호작용 정책 검증")
struct KeyboardTextInteractionPolicyTests {

    @Test("보조키 입력은 요청되었고 보조키가 있을 때만 수행")
    func test보조키입력조건() {
        #expect(
            KeyboardTextInteractionPolicy.shouldInsertSecondaryKey(
                insertSecondaryKeyIfAvailable: true,
                secondaryKey: "1"
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldInsertSecondaryKey(
                insertSecondaryKeyIfAvailable: false,
                secondaryKey: "1"
            ) == false
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldInsertSecondaryKey(
                insertSecondaryKeyIfAvailable: true,
                secondaryKey: nil
            ) == false
        )
    }

    @Test("단일 삭제 임시 저장 문자는 선택 텍스트를 역순으로 우선 사용")
    func test단일삭제임시저장문자() {
        #expect(
            KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                selectedText: "abc",
                documentContextBeforeInput: "가나다"
            ) == "cba"
        )
        #expect(
            KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                selectedText: "",
                documentContextBeforeInput: "가나다"
            ) == "다"
        )
        #expect(
            KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                selectedText: nil,
                documentContextBeforeInput: "가나다"
            ) == "다"
        )
        #expect(
            KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                selectedText: nil,
                documentContextBeforeInput: nil
            ) == ""
        )
    }

    @Test("단일 삭제 기록 문자는 비어 있지 않은 선택 텍스트를 원문으로 우선 사용")
    func test단일삭제기록문자() {
        #expect(
            KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: "abc",
                documentContextBeforeInput: "가나다"
            ) == "abc"
        )
        #expect(
            KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: "",
                documentContextBeforeInput: "가나다"
            ) == "다"
        )
        #expect(
            KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: nil,
                documentContextBeforeInput: nil
            ) == ""
        )
    }

    @Test("반복 삭제는 커서 앞 문맥이나 선택 텍스트가 있을 때만 수행")
    func test반복삭제조건() {
        #expect(
            KeyboardTextInteractionPolicy.shouldRepeatDelete(
                documentContextBeforeInput: "가",
                selectedText: nil
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRepeatDelete(
                documentContextBeforeInput: nil,
                selectedText: "나"
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRepeatDelete(
                documentContextBeforeInput: nil,
                selectedText: ""
            ) == false
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRepeatDelete(
                documentContextBeforeInput: nil,
                selectedText: nil
            ) == false
        )
    }

    @Test("반복 입력 타이머 간격은 최소값 아래로 내려가지 않음")
    func test반복입력타이머간격최소값() {
        expectRepeatTimerInterval(repeatRate: 0.05, expected: 0.05)
        expectRepeatTimerInterval(repeatRate: 0.09, expected: 0.01)
        expectRepeatTimerInterval(repeatRate: 0.10, expected: 0.01)
        expectRepeatTimerInterval(repeatRate: 0.20, expected: 0.01)
    }
}

private extension KeyboardTextInteractionPolicyTests {
    func expectRepeatTimerInterval(repeatRate: Double, expected: Double) {
        let interval = KeyboardTextInteractionPolicy.repeatTimerInterval(repeatRate: repeatRate)

        #expect(abs(interval - expected) < 0.0001)
    }
}
