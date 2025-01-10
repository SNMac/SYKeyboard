//
//  PreviewNaratgeulState.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/10/25.
//

import Foundation

enum PreviewOneHandType: Int {
    case left
    case center
    case right
}

final class PreviewNaratgeulState: ObservableObject {
    @Published var currentOneHandType: PreviewOneHandType = .center
    
    var nowPressedButton: PreviewNaratgeulButton?
}
