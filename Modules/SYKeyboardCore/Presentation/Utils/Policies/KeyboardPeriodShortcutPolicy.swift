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
