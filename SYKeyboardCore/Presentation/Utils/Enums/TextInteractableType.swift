//
//  TextInteractableType.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/3/25.
//

/// 입력 상호작용 버튼 관리용
public enum TextInteractableType {
    case keyButton(keys: [String])
    case deleteButton
    case spaceButton
    case returnButton
    
    public var keys: [String] {
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
