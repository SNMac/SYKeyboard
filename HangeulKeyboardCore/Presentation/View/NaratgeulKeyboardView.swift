//
//  NaratgeulKeyboardView.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SYKeyboardCore

/// 나랏글 키보드
final class NaratgeulKeyboardView: FourByFourKeyboardView, HangeulKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    override var keyboard: SYKeyboardType { .naratgeul }

    /// 나랏글 키보드 키 배열
    override var primaryKeyList: [[[String]]] {
        [
            [ ["ㄱ"], ["ㄴ"], ["ㅏ", "ㅓ"] ],
            [ ["ㄹ"], ["ㅁ"], ["ㅗ", "ㅜ"] ],
            [ ["ㅅ"], ["ㅇ"], ["ㅣ"] ],
            [ ["획"], ["ㅡ"], ["쌍"] ]
        ]
    }
    
    override var secondaryKeyList: [[[String]]] {
        [
            [ ["1"], ["2"], ["3"] ],
            [ ["4"], ["5"], ["6"] ],
            [ ["7"], ["8"], ["9"] ],
            [ ["획"], ["0"], ["쌍"] ]
        ]
    }
    
    final var currentHangeulKeyboardMode: HangeulKeyboardMode = .default {
        didSet(oldMode) { updateLayoutForCurrentHangeulMode(oldMode: oldMode) }
    }
    
    init() {
        super.init(frame: .zero)
        updateLayoutToDefault()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
