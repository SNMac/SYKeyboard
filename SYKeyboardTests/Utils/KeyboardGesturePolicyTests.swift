//
//  KeyboardGesturePolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 5/22/26.
//

import Testing
import UIKit

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

    @Test("textDidChange 커서 햅틱은 primary 드래그의 실제 문맥 변경에만 재생")
    func testTextDidChange커서햅틱조건() {
        let requestContext = KeyboardTextContextSnapshot(
            beforeInput: "가",
            afterInput: ""
        )
        let movedContext = KeyboardTextContextSnapshot(
            beforeInput: "가\n",
            afterInput: ""
        )

        #expect(
            KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
                isPrimaryCursorDragging: true,
                pendingRequestContext: requestContext,
                currentContext: movedContext
            )
        )
        #expect(
            KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
                isPrimaryCursorDragging: true,
                pendingRequestContext: requestContext,
                currentContext: requestContext
            ) == false
        )
        #expect(
            KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
                isPrimaryCursorDragging: true,
                pendingRequestContext: nil,
                currentContext: movedContext
            ) == false
        )
        #expect(
            KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
                isPrimaryCursorDragging: false,
                pendingRequestContext: requestContext,
                currentContext: movedContext
            ) == false
        )
    }

    @Test("커서 문맥의 nil과 빈 문자열은 같은 위치로 취급")
    func testTextDidChange커서햅틱_nil빈문맥동일취급() {
        #expect(
            KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
                isPrimaryCursorDragging: true,
                pendingRequestContext: KeyboardTextContextSnapshot(
                    beforeInput: "가",
                    afterInput: nil
                ),
                currentContext: KeyboardTextContextSnapshot(
                    beforeInput: "가",
                    afterInput: ""
                )
            ) == false
        )
    }

    @Test("system gesture recognizer는 edge key touch 지연과 취소를 비활성화")
    func testSystemGestureTouchDelay해제정책() {
        let gesture = UIGestureRecognizer()
        gesture.delaysTouchesBegan = true
        gesture.delaysTouchesEnded = true
        gesture.cancelsTouchesInView = true

        KeyboardGesturePolicy.configureSystemGestureForEdgeTouch(gesture)

        #expect(gesture.delaysTouchesBegan == false)
        #expect(gesture.delaysTouchesEnded == false)
        #expect(gesture.cancelsTouchesInView == false)
    }

    @Test("screen edge pan gesture는 edge key touch를 가로채지 않도록 비활성화")
    func testScreenEdgePanGesture비활성화정책() {
        let gesture = UIScreenEdgePanGestureRecognizer()
        gesture.isEnabled = true

        KeyboardGesturePolicy.configureSystemGestureForEdgeTouch(gesture)

        #expect(gesture.isEnabled == false)
    }
}
