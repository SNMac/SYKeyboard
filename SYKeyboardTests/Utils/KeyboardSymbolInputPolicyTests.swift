//
//  KeyboardSymbolInputPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 5/22/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("심볼 키보드 입력 정책 검증")
struct KeyboardSymbolInputPolicyTests {

    @Test("작은따옴표 입력 후 조건이 맞으면 기본 키보드로 전환")
    func test작은따옴표입력후기본키보드전환조건() {
        let apostrophe = TextInteractableType.keyButton(primary: ["'"], secondary: nil)

        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
                buttonType: apostrophe,
                keyboardType: .default,
                isAutoChangeToPrimaryEnabled: true
            )
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
                buttonType: apostrophe,
                keyboardType: .numbersAndPunctuation,
                isAutoChangeToPrimaryEnabled: true
            ) == false
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
                buttonType: .keyButton(primary: ["!"], secondary: nil),
                keyboardType: .default,
                isAutoChangeToPrimaryEnabled: true
            ) == false
        )
    }

    @Test("스페이스나 리턴 입력 후 심볼 입력 상태이면 기본 키보드로 전환")
    func test스페이스리턴입력후기본키보드전환조건() {
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterSpaceOrReturn(
                buttonType: .spaceButton,
                keyboardType: .default,
                isAutoChangeToPrimaryEnabled: true,
                isSymbolInput: true
            )
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterSpaceOrReturn(
                buttonType: .returnButton,
                keyboardType: .default,
                isAutoChangeToPrimaryEnabled: true,
                isSymbolInput: true
            )
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterSpaceOrReturn(
                buttonType: .spaceButton,
                keyboardType: .numbersAndPunctuation,
                isAutoChangeToPrimaryEnabled: true,
                isSymbolInput: true
            ) == false
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterSpaceOrReturn(
                buttonType: .spaceButton,
                keyboardType: .default,
                isAutoChangeToPrimaryEnabled: true,
                isSymbolInput: false
            ) == false
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterSpaceOrReturn(
                buttonType: .keyButton(primary: ["!"], secondary: nil),
                keyboardType: .default,
                isAutoChangeToPrimaryEnabled: true,
                isSymbolInput: true
            ) == false
        )
    }

    @Test("작은따옴표와 삭제 스페이스 리턴을 제외한 심볼 키는 심볼 입력 상태로 표시")
    func test심볼입력상태표시조건() {
        #expect(
            KeyboardSymbolInputPolicy.shouldMarkSymbolInput(
                buttonType: .keyButton(primary: ["!"], secondary: nil)
            )
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldMarkSymbolInput(
                buttonType: .keyButton(primary: ["'"], secondary: nil)
            ) == false
        )
        #expect(KeyboardSymbolInputPolicy.shouldMarkSymbolInput(buttonType: .deleteButton) == false)
        #expect(KeyboardSymbolInputPolicy.shouldMarkSymbolInput(buttonType: .spaceButton) == false)
        #expect(KeyboardSymbolInputPolicy.shouldMarkSymbolInput(buttonType: .returnButton) == false)
    }
}
