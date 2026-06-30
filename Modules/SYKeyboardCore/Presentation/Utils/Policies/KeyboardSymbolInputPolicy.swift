//
//  KeyboardSymbolInputPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

import UIKit

enum KeyboardSymbolInputPolicy {

    static func shouldSwitchToPrimaryAfterApostropheInput(
        buttonType: TextInteractableType,
        keyboardType: UIKeyboardType,
        isAutoChangeToPrimaryEnabled: Bool
    ) -> Bool {
        guard isApostropheKey(buttonType),
              keyboardType != .numbersAndPunctuation,
              isAutoChangeToPrimaryEnabled else { return false }
        return true
    }

    static func shouldSwitchToPrimaryAfterSpaceOrReturn(
        buttonType: TextInteractableType,
        keyboardType: UIKeyboardType,
        isAutoChangeToPrimaryEnabled: Bool,
        isSymbolInput: Bool
    ) -> Bool {
        guard isSpaceOrReturn(buttonType),
              keyboardType != .numbersAndPunctuation,
              isAutoChangeToPrimaryEnabled,
              isSymbolInput else { return false }
        return true
    }

    static func shouldMarkSymbolInput(buttonType: TextInteractableType) -> Bool {
        switch buttonType {
        case .keyButton where isApostropheKey(buttonType),
             .deleteButton,
             .spaceButton,
             .returnButton:
            return false
        default:
            return true
        }
    }

    static func isApostropheKey(_ buttonType: TextInteractableType) -> Bool {
        guard case .keyButton(let primary, nil) = buttonType,
              primary.count == 1,
              let character = primary.first?.first else {
            return false
        }

        return ["'", "‘", "’"].contains(character)
    }
}

private extension KeyboardSymbolInputPolicy {
    static func isSpaceOrReturn(_ buttonType: TextInteractableType) -> Bool {
        switch buttonType {
        case .spaceButton, .returnButton:
            return true
        default:
            return false
        }
    }
}
