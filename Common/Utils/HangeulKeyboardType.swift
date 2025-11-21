//
//  HangeulKeyboardType.swift
//  SYKeyboard, HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/13/25.
//

/// 한글 키보드 종류 관리용
enum HangeulKeyboardType: Int {
    case naratgeul
    case cheonjiin
    
    var title: String {
        switch self {
        case .naratgeul:
            return "나랏글"
        case .cheonjiin:
            return "천지인"
        }
    }
}
