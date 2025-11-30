//
//  TextInteractableType.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/3/25.
//

/// 입력 상호작용 버튼 관리용
public enum TextInteractableType {
    case keyButton(primary: [String], secondary: String?)
    case deleteButton
    case spaceButton
    case returnButton
    
    public var primaryKeyList: [String] {
        switch self {
        case .keyButton(let primary, _):
            return primary
        case .deleteButton:
            return []
        case .spaceButton:
            return [" "]
        case .returnButton:
            return ["\n"]
        }
    }
    
    public var secondaryKey: String? {
        switch self {
        case .keyButton(_, let secondary):
            return secondary
        case .deleteButton:
            return nil
        case .spaceButton:
            return nil
        case .returnButton:
            return nil
        }
    }
}
