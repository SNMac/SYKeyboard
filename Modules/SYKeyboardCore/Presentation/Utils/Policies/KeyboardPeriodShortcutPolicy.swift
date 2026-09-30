//
//  KeyboardPeriodShortcutPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

struct KeyboardPeriodShortcutState {
    let performedPeriodShortcut: Bool
    let preventsNextPeriodShortcut: Bool
}

enum KeyboardPeriodShortcutPolicy {

    static func shouldReplaceTrailingSpaceWithPeriod(
        isPreview: Bool,
        preventsNextPeriodShortcut: Bool,
        documentContextBeforeInput: String?
    ) -> Bool {
        guard !isPreview,
              !preventsNextPeriodShortcut,
              let beforeInput = documentContextBeforeInput,
              beforeInput.hasSuffix(" ") else { return false }

        let textWithoutLastSpace = beforeInput.dropLast()
        guard let lastCharacter = textWithoutLastSpace.last else { return false }
        return lastCharacter.isLetter || lastCharacter.isNumber
    }

    /// `stateAfterDelete`가 `documentContextBeforeInput`을 실제로 사용하는 상태인지 여부.
    ///
    /// 이 값이 `false`면 어떤 커서 앞 텍스트를 넘겨도 결과가 같으므로,
    /// 호출부는 `UITextDocumentProxy` 조회를 건너뛸 수 있다.
    static func requiresDocumentContextAfterDelete(
        isPeriodShortcutEnabled: Bool,
        performedPeriodShortcut: Bool,
        preventsNextPeriodShortcut: Bool
    ) -> Bool {
        return isPeriodShortcutEnabled && !performedPeriodShortcut && preventsNextPeriodShortcut
    }

    static func stateAfterDelete(
        isPeriodShortcutEnabled: Bool,
        performedPeriodShortcut: Bool,
        preventsNextPeriodShortcut: Bool,
        documentContextBeforeInput: String?
    ) -> KeyboardPeriodShortcutState {
        guard isPeriodShortcutEnabled else {
            return KeyboardPeriodShortcutState(
                performedPeriodShortcut: performedPeriodShortcut,
                preventsNextPeriodShortcut: preventsNextPeriodShortcut
            )
        }

        if performedPeriodShortcut {
            return KeyboardPeriodShortcutState(
                performedPeriodShortcut: false,
                preventsNextPeriodShortcut: true
            )
        }

        if preventsNextPeriodShortcut,
           let lastCharacter = documentContextBeforeInput?.last,
           lastCharacter.isLetter || lastCharacter.isNumber {
            return KeyboardPeriodShortcutState(
                performedPeriodShortcut: false,
                preventsNextPeriodShortcut: false
            )
        }

        return KeyboardPeriodShortcutState(
            performedPeriodShortcut: performedPeriodShortcut,
            preventsNextPeriodShortcut: preventsNextPeriodShortcut
        )
    }
}
