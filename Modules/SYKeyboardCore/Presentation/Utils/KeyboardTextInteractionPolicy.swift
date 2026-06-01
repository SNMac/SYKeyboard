//
//  KeyboardTextInteractionPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

enum KeyboardTextInteractionPolicy {

    static func shouldInsertSecondaryKey(
        insertSecondaryKeyIfAvailable: Bool,
        secondaryKey: String?
    ) -> Bool {
        return insertSecondaryKeyIfAvailable && secondaryKey != nil
    }

    static func temporaryDeletedCharactersForSingleDelete(
        selectedText: String?,
        documentContextBeforeInput: String?
    ) -> String {
        if let selectedText {
            return String(selectedText.reversed())
        }
        if let lastBeforeCursor = documentContextBeforeInput?.last {
            return String(lastBeforeCursor)
        }
        return ""
    }

    static func deletedTextForSingleBackward(
        selectedText: String?,
        documentContextBeforeInput: String?
    ) -> String {
        if let selectedText, !selectedText.isEmpty {
            return selectedText
        }
        if let lastBeforeCursor = documentContextBeforeInput?.last {
            return String(lastBeforeCursor)
        }
        return ""
    }

    static func shouldRepeatDelete(
        documentContextBeforeInput: String?,
        selectedText: String?
    ) -> Bool {
        return documentContextBeforeInput != nil || selectedText != nil
    }
}
