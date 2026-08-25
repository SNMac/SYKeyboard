//
//  KeyboardPeriodShortcutPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 5/22/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("마침표 단축 입력 정책 검증")
struct KeyboardPeriodShortcutPolicyTests {

    @Test("스페이스 앞 글자가 문자나 숫자이면 마침표 단축 입력 수행")
    func test마침표단축입력수행조건() {
        #expect(
            KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                isPreview: false,
                preventsNextPeriodShortcut: false,
                documentContextBeforeInput: "hello "
            )
        )
        #expect(
            KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                isPreview: false,
                preventsNextPeriodShortcut: false,
                documentContextBeforeInput: "123 "
            )
        )
        #expect(
            KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                isPreview: false,
                preventsNextPeriodShortcut: false,
                documentContextBeforeInput: "안녕 "
            )
        )
    }

    @Test("preview 또는 방지 상태이거나 공백 앞 글자가 문자 숫자가 아니면 마침표 단축 입력을 수행하지 않음")
    func test마침표단축입력차단조건() {
        #expect(
            KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                isPreview: true,
                preventsNextPeriodShortcut: false,
                documentContextBeforeInput: "hello "
            ) == false
        )
        #expect(
            KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                isPreview: false,
                preventsNextPeriodShortcut: true,
                documentContextBeforeInput: "hello "
            ) == false
        )
        #expect(
            KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                isPreview: false,
                preventsNextPeriodShortcut: false,
                documentContextBeforeInput: "hello"
            ) == false
        )
        #expect(
            KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                isPreview: false,
                preventsNextPeriodShortcut: false,
                documentContextBeforeInput: "# "
            ) == false
        )
        #expect(
            KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                isPreview: false,
                preventsNextPeriodShortcut: false,
                documentContextBeforeInput: nil
            ) == false
        )
    }

    @Test("마침표 단축 입력 직후 삭제하면 다음 단축 입력을 한 번 방지")
    func test삭제후마침표단축입력방지상태전환() {
        let state = KeyboardPeriodShortcutPolicy.stateAfterDelete(
            isPeriodShortcutEnabled: true,
            performedPeriodShortcut: true,
            preventsNextPeriodShortcut: false,
            documentContextBeforeInput: nil
        )

        #expect(state.performedPeriodShortcut == false)
        #expect(state.preventsNextPeriodShortcut == true)
    }

    @Test("방지 상태에서 커서 앞 글자가 문자나 숫자이면 방지를 해제")
    func test마침표단축입력방지상태해제() {
        let state = KeyboardPeriodShortcutPolicy.stateAfterDelete(
            isPeriodShortcutEnabled: true,
            performedPeriodShortcut: false,
            preventsNextPeriodShortcut: true,
            documentContextBeforeInput: "a"
        )

        #expect(state.performedPeriodShortcut == false)
        #expect(state.preventsNextPeriodShortcut == false)
    }

    @Test("커서 앞 텍스트가 필요 없다고 판정한 상태에서는 어떤 텍스트를 넘겨도 결과가 같음")
    func test삭제후커서앞텍스트필요여부판정() {
        let contexts: [String?] = [nil, "", " ", "a", "1", ". ", "가"]
        let flags = [true, false]

        for isEnabled in flags {
            for performed in flags {
                for prevents in flags {
                    let requiresContext = KeyboardPeriodShortcutPolicy.requiresDocumentContextAfterDelete(
                        isPeriodShortcutEnabled: isEnabled,
                        performedPeriodShortcut: performed,
                        preventsNextPeriodShortcut: prevents
                    )
                    guard !requiresContext else { continue }

                    let states = contexts.map {
                        KeyboardPeriodShortcutPolicy.stateAfterDelete(
                            isPeriodShortcutEnabled: isEnabled,
                            performedPeriodShortcut: performed,
                            preventsNextPeriodShortcut: prevents,
                            documentContextBeforeInput: $0
                        )
                    }

                    #expect(states.allSatisfy { $0.performedPeriodShortcut == states[0].performedPeriodShortcut })
                    #expect(states.allSatisfy { $0.preventsNextPeriodShortcut == states[0].preventsNextPeriodShortcut })
                }
            }
        }
    }

    @Test("커서 앞 텍스트가 필요한 상태에서는 텍스트에 따라 결과가 달라짐")
    func test삭제후커서앞텍스트필요상태의결과차이() {
        #expect(
            KeyboardPeriodShortcutPolicy.requiresDocumentContextAfterDelete(
                isPeriodShortcutEnabled: true,
                performedPeriodShortcut: false,
                preventsNextPeriodShortcut: true
            )
        )

        let letterState = KeyboardPeriodShortcutPolicy.stateAfterDelete(
            isPeriodShortcutEnabled: true,
            performedPeriodShortcut: false,
            preventsNextPeriodShortcut: true,
            documentContextBeforeInput: "a"
        )
        let spaceState = KeyboardPeriodShortcutPolicy.stateAfterDelete(
            isPeriodShortcutEnabled: true,
            performedPeriodShortcut: false,
            preventsNextPeriodShortcut: true,
            documentContextBeforeInput: " "
        )

        #expect(letterState.preventsNextPeriodShortcut == false)
        #expect(spaceState.preventsNextPeriodShortcut == true)
    }

    @Test("설정이 꺼져 있으면 삭제 후 마침표 단축 입력 상태를 바꾸지 않음")
    func test마침표단축입력설정꺼짐상태유지() {
        let state = KeyboardPeriodShortcutPolicy.stateAfterDelete(
            isPeriodShortcutEnabled: false,
            performedPeriodShortcut: true,
            preventsNextPeriodShortcut: false,
            documentContextBeforeInput: "a"
        )

        #expect(state.performedPeriodShortcut == true)
        #expect(state.preventsNextPeriodShortcut == false)
    }
}
