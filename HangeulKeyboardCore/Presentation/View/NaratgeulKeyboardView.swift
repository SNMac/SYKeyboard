//
//  NaratgeulKeyboardView.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 나랏글 키보드
final class NaratgeulKeyboardView: FourByFourKeyboardView {
    
    // MARK: - Properties

    /// 나랏글 키보드 키 배열
    override var hangeulKeyList: [[[String]]] {
        [
            [ ["ㄱ"], ["ㄴ"], ["ㅏ", "ㅓ"] ],
            [ ["ㄹ"], ["ㅁ"], ["ㅗ", "ㅜ"] ],
            [ ["ㅅ"], ["ㅇ"], ["ㅣ"] ],
            [ ["획"], ["ㅡ"], ["쌍"] ]
        ]
    }
}
