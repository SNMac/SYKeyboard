//
//  SymbolKeyboardMode.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

public enum SymbolKeyboardMode: Equatable {
    case `default`
    case URL
    case emailAddress
    case webSearch

    public init(keyboardType: UIKeyboardType?) {
        switch keyboardType {
        case .URL:
            self = .URL
        case .emailAddress:
            self = .emailAddress
        case .webSearch:
            self = .webSearch
        default:
            self = .default
        }
    }
    
    /// 기호 자판 배열. 네 모드가 같은 배열을 쓴다.
    /// 모드에 따라 달라지는 것은 스페이스 옆 키 구성뿐이다
    /// - Parameter usesNumberRow: 자판 위에 숫자 행이 있는지 여부.
    ///   숫자 행이 있으면 첫 줄 숫자가 중복되므로 기호로 채운다
    static func keyList(usesNumberRow: Bool) -> [[[[String]]]] {
        guard usesNumberRow else {
            return [
                [
                    [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                    [ ["-"], ["/"], [":"], [";"], ["("], [")"], ["₩"], ["&"], ["@"], ["”"] ],
                    [ ["."], [","], ["?"], ["!"], ["’"] ]
                ],
                [
                    [ ["["], ["]"], ["{"], ["}"], ["#"], ["%"], ["^"], ["*"], ["+"], ["="] ],
                    [ ["_"], ["\\"], ["|"], ["~"], ["<"], [">"], ["$"], ["£"], ["¥"], ["•"] ],
                    [ ["."], [","], ["?"], ["!"], ["’"] ]
                ]
            ]
        }
        // 숫자 밑에 있던 줄을 숫자 행 밑에 그대로 두고, 새 줄을 그 아래에 넣는다
        return [
            [
                [ ["-"], ["/"], [":"], [";"], ["("], [")"], ["₩"], ["&"], ["@"], ["”"] ],
                [ ["["], ["]"], ["{"], ["}"], ["#"], ["%"], ["^"], ["*"], ["+"], ["="] ],
                [ ["."], [","], ["?"], ["!"], ["’"] ]
            ],
            [
                [ ["_"], ["\\"], ["|"], ["~"], ["<"], [">"], ["$"], ["£"], ["¥"], ["•"] ],
                [ ["※"], ["☆"], ["★"], ["○"], ["●"], ["□"], ["■"], ["△"], ["▲"], ["♡"] ],
                [ ["."], [","], ["?"], ["!"], ["’"] ]
            ]
        ]
    }
}
