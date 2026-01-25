//
//  HangeulKeyboardType.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/13/25.
//

/// 한글 키보드 종류 관리용
public enum HangeulKeyboardType: Int {
    case naratgeul
    case cheonjiin
    case dubeolsik
    
    var title: String {
        switch self {
        case .naratgeul:
            "나랏글"
        case .cheonjiin:
            "천지인"
        case .dubeolsik:
            "두벌식"
        }
    }
}
