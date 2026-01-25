//
//  EnglishKeyboardMode.swift
//  EnglishKeyboardCore
//
//  Created by 서동환 on 9/6/25.
//

enum EnglishKeyboardMode {
    case `default`
    case URL
    case emailAddress
    case twitter
    case webSearch
    
    var primaryKeyList: [[[[String]]]] {
        switch self {
        default:
            return [
                [
                    [ ["q"], ["w"], ["e"], ["r"], ["t"], ["y"], ["u"], ["i"], ["o"], ["p"] ],
                    [ ["a"], ["s"], ["d"], ["f"], ["g"], ["h"], ["j"], ["k"], ["l"] ],
                    [ ["z"], ["x"], ["c"], ["v"], ["b"], ["n"], ["m"] ]
                ],
                [
                    [ ["Q"], ["W"], ["E"], ["R"], ["T"], ["Y"], ["U"], ["I"], ["O"], ["P"] ],
                    [ ["A"], ["S"], ["D"], ["F"], ["G"], ["H"], ["J"], ["K"], ["L"] ],
                    [ ["Z"], ["X"], ["C"], ["V"], ["B"], ["N"], ["M"] ]
                ]
            ]
        }
    }
    
    var secondaryKeyList: [[[[String]]]] {
        switch self {
        default:
            return [
                [
                    [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                    [ [], [], [], [], [], [], [], [], [] ],
                    [ [], [], [], [], [], [], [] ]
                ],
                [
                    [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                    [ [], [], [], [], [], [], [], [], [] ],
                    [ [], [], [], [], [], [], [] ]
                ]
            ]
        }
    }
}
