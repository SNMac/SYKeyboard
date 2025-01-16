//
//  PreviewNaratgeulState.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/10/25.
//

import SwiftUI

enum PreviewOneHandMode: Int {
    case left
    case center
    case right
}

final class PreviewNaratgeulState: ObservableObject {
    @Published var currentOneHandMode: PreviewOneHandMode = .center
    
    var nowPressedButton: PreviewNaratgeulButton?
}
