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

    @Test("UIKeyboardType은 대응하는 기호 키보드 모드로 매핑")
    func testUIKeyboardType별기호키보드모드() {
        #expect(SymbolKeyboardMode(keyboardType: nil) == .default)
        #expect(SymbolKeyboardMode(keyboardType: .default) == .default)
        #expect(SymbolKeyboardMode(keyboardType: .numbersAndPunctuation) == .default)
        #expect(SymbolKeyboardMode(keyboardType: .URL) == .URL)
        #expect(SymbolKeyboardMode(keyboardType: .emailAddress) == .emailAddress)
        #expect(SymbolKeyboardMode(keyboardType: .webSearch) == .webSearch)
        #expect(SymbolKeyboardMode(keyboardType: .twitter) == .default)
    }

    @Test("기호 키보드 모드는 일반과 Shift 키 배열을 제공")
    func test기호키보드모드별키배열() {
        #expect(
            SymbolKeyboardMode.default.keyList[0][1].map { $0.first ?? "" } ==
            ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"]
        )
        #expect(
            SymbolKeyboardMode.URL.keyList[0][2].map { $0.first ?? "" } ==
            ["_", ":", "-", "+", ""]
        )
        #expect(
            SymbolKeyboardMode.emailAddress.keyList[0][2].map { $0.first ?? "" } ==
            [".", "_", "-", "+", ""]
        )
        #expect(SymbolKeyboardMode.webSearch.keyList == SymbolKeyboardMode.default.keyList)
    }

    @MainActor
    @Test("기호 키보드 작은따옴표 키는 닫는 따옴표를 표시")
    func test기호키보드작은따옴표표시() {
        let symbolKeyboardView = SymbolKeyboardView()
        let unshiftedApostrophe = symbolKeyboardView.lastPrimaryKeyButton?.type.primaryKeyList.first

        symbolKeyboardView.isShifted = true
        let shiftedApostrophe = symbolKeyboardView.lastPrimaryKeyButton?.type.primaryKeyList.first

        #expect(unshiftedApostrophe == "’")
        #expect(shiftedApostrophe == "’")
    }

    @Test("작은따옴표 입력 후 조건이 맞으면 기본 키보드로 전환")
    func test작은따옴표입력후기본키보드전환조건() {
        let apostrophe = TextInteractableType.keyButton(primary: ["'"], secondary: nil)
        let closingSmartApostrophe = TextInteractableType.keyButton(primary: ["’"], secondary: nil)
        let openingSmartApostrophe = TextInteractableType.keyButton(primary: ["‘"], secondary: nil)

        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
                buttonType: apostrophe,
                keyboardType: .default,
                isAutoChangeToPrimaryEnabled: true
            )
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
                buttonType: closingSmartApostrophe,
                keyboardType: .default,
                isAutoChangeToPrimaryEnabled: true
            )
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
                buttonType: openingSmartApostrophe,
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
        #expect(
            KeyboardSymbolInputPolicy.shouldMarkSymbolInput(
                buttonType: .keyButton(primary: ["’"], secondary: nil)
            ) == false
        )
        #expect(
            KeyboardSymbolInputPolicy.shouldMarkSymbolInput(
                buttonType: .keyButton(primary: ["‘"], secondary: nil)
            ) == false
        )
        #expect(KeyboardSymbolInputPolicy.shouldMarkSymbolInput(buttonType: .deleteButton) == false)
        #expect(KeyboardSymbolInputPolicy.shouldMarkSymbolInput(buttonType: .spaceButton) == false)
        #expect(KeyboardSymbolInputPolicy.shouldMarkSymbolInput(buttonType: .returnButton) == false)
    }
}

private extension SymbolKeyboardView {
    var lastPrimaryKeyButton: PrimaryKeyButton? {
        primaryButtonList.compactMap { $0 as? PrimaryKeyButton }.last
    }
}
