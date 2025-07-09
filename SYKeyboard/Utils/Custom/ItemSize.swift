//
//  ItemSize.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/22/25.
//

import SwiftUI

struct ItemSize: PreferenceKey {
    static var defaultValue: CGSize { .zero }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        let next = nextValue()
        value = CGSize(width: max(value.width,next.width),
                       height: max(value.height,next.height))
    }
}
