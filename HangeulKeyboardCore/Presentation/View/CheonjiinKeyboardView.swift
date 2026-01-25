//
//  CheonjiinKeyboardView.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SYKeyboardCore

/// 천지인 키보드
final class CheonjiinKeyboardView: FourByFourPlusKeyboardView, HangeulKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    override var keyboard: SYKeyboardType { .cheonjiin }
    
    /// 나랏글 키보드 키 배열
    override var primaryKeyList: [[[String]]] {
        [
            [ ["ㅣ"], ["ㆍ"], ["ㅡ"] ],
            [ ["ㄱ", "ㅋ"], ["ㄴ", "ㄹ"], ["ㄷ", "ㅌ"] ],
            [ ["ㅂ", "ㅍ"], ["ㅅ", "ㅎ"], ["ㅈ", "ㅊ"] ],
            [ ["."], [","], ["ㅇ", "ㅁ"], ["?"], ["!"] ]
        ]
    }
    
    override var secondaryKeyList: [[[String]]] {
        [
            [ ["1"], ["2"], ["3"] ],
            [ ["4"], ["5"], ["6"] ],
            [ ["7"], ["8"], ["9"] ],
            [ [], [], ["0"], [], [] ]
        ]
    }
    
    final var currentHangeulKeyboardMode: HangeulKeyboardMode = .default {
        didSet(oldMode) { updateLayoutForCurrentHangeulMode(oldMode: oldMode) }
    }
    
    var isShifted: Bool = false
    var wasShifted: Bool = false
    
    // MARK: - Initializer
    
    init() {
        super.init(frame: .zero)
        updateLayoutToDefault()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
