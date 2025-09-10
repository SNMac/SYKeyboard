//
//  TextInteractionButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/3/25.
//

enum TextInteractionButton {
    case keyButton(keys: [String])
    case deleteButton
    case spaceButton
    case returnButton
    
    var keys: [String] {
        switch self {
        case .keyButton(let keys):
            return keys
        case .deleteButton:
            return []
        case .spaceButton:
            return [" "]
        case .returnButton:
            return ["\n"]
        }
    }
}
