//
//  KeyboardGesturePolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 5/22/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("키보드 제스처 정책 검증")
struct KeyboardGesturePolicyTests {

    @Test("커서 이동 설정이 켜졌거나 삭제 버튼이면 pan gesture를 추가")
    func testPanGesture추가조건() {
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionPanGesture(
                isDragToMoveCursorEnabled: false,
                isDeleteButton: false
            ) == false
        )
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionPanGesture(
                isDragToMoveCursorEnabled: true,
                isDeleteButton: false
            ) == true
        )
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionPanGesture(
                isDragToMoveCursorEnabled: false,
                isDeleteButton: true
            ) == true
        )
    }

    @Test("리턴 보조키 닷컴 키는 text interaction gesture 등록 대상에서 제외")
    func testTextInteractionGesture등록대상조건() {
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionGestures(
                isReturnButton: false,
                isSecondaryKeyButton: false,
                primaryKeyList: ["A"]
            )
        )
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionGestures(
                isReturnButton: true,
                isSecondaryKeyButton: false,
                primaryKeyList: ["\n"]
            ) == false
        )
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionGestures(
                isReturnButton: false,
                isSecondaryKeyButton: true,
                primaryKeyList: ["1"]
            ) == false
        )
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionGestures(
                isReturnButton: false,
                isSecondaryKeyButton: false,
                primaryKeyList: [".com"]
            ) == false
        )
    }

    @Test("길게 누르기 설정이 꺼져도 삭제 버튼이면 long press gesture를 추가")
    func testLongPressGesture추가조건() {
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionLongPressGesture(
                selectedLongPressAction: .disabled,
                isDeleteButton: false
            ) == false
        )
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionLongPressGesture(
                selectedLongPressAction: .numberInput,
                isDeleteButton: false
            ) == true
        )
        #expect(
            KeyboardGesturePolicy.shouldAddTextInteractionLongPressGesture(
                selectedLongPressAction: .disabled,
                isDeleteButton: true
            ) == true
        )
    }

    @Test("삭제 버튼 long press는 설정과 무관하게 반복 입력으로 처리")
    func testLongPress반복입력조건() {
        #expect(
            KeyboardGesturePolicy.shouldPerformRepeatInputOnLongPress(
                selectedLongPressAction: .numberInput,
                isDeleteButton: false
            ) == false
        )
        #expect(
            KeyboardGesturePolicy.shouldPerformRepeatInputOnLongPress(
                selectedLongPressAction: .repeatInput,
                isDeleteButton: false
            ) == true
        )
        #expect(
            KeyboardGesturePolicy.shouldPerformRepeatInputOnLongPress(
                selectedLongPressAction: .disabled,
                isDeleteButton: true
            ) == true
        )
    }

    @Test("숫자 입력 long press는 삭제 버튼이 아니고 numberInput 설정일 때만 수행")
    func testLongPress숫자입력조건() {
        #expect(
            KeyboardGesturePolicy.shouldPerformNumberInputOnLongPress(
                selectedLongPressAction: .numberInput,
                isDeleteButton: false
            ) == true
        )
        #expect(
            KeyboardGesturePolicy.shouldPerformNumberInputOnLongPress(
                selectedLongPressAction: .repeatInput,
                isDeleteButton: false
            ) == false
        )
        #expect(
            KeyboardGesturePolicy.shouldPerformNumberInputOnLongPress(
                selectedLongPressAction: .numberInput,
                isDeleteButton: true
            ) == false
        )
    }
}
