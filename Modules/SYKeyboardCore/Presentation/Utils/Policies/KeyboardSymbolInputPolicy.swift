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

    /// 길게 누르기 입력은 터치가 취소되어 `touchUpInside`가 오지 않으므로 입력 시점에 따로 표시한다
    static func shouldMarkSymbolInputAfterLongPressInput(
        buttonType: TextInteractableType,
        currentKeyboard: SYKeyboardType
    ) -> Bool {
        return currentKeyboard == .symbol && shouldMarkSymbolInput(buttonType: buttonType)
    }

    /// 길게 누르기로 입력한 작은따옴표는 손을 뗄 때 탭과 같은 조건으로 전환하도록 기록한다
    static func shouldRecordApostropheLongPressInput(
        buttonType: TextInteractableType,
        currentKeyboard: SYKeyboardType
    ) -> Bool {
        return currentKeyboard == .symbol && isApostropheKey(buttonType)
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
