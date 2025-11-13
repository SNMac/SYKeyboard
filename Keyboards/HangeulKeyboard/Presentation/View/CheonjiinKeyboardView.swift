//
//  CheonjiinKeyboardView.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 천지인 키보드
final class CheonjiinKeyboardView: FourByFourKeyboardView {
    
    // MARK: - Properties
    
    /// 나랏글 키보드 키 배열
    override var hangeulKeyList: [[[String]]] {
        [
            [ ["ㅣ"], ["ㆍ"], ["ㅡ"] ],
            [ ["ㄱ", "ㅋ"], ["ㄴ", "ㄹ"], ["ㄷ", "ㅌ"] ],
            [ ["ㅂ", "ㅍ"], ["ㅅ", "ㅎ"], ["ㅈ", "ㅊ"] ],
            [ [".", ","], ["ㅇ", "ㅁ"], ["?", "!"] ]
        ]
    }
}
