//
//  PreviewKeyboardState.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/10/25.
//

import SwiftUI

enum PreviewOneHandedKeyboard: Int {
    case left
    case center
    case right
}

final class PreviewKeyboardState: ObservableObject {
    @Published var currentOneHandedKeyboard: PreviewOneHandedKeyboard = .center
    
    var nowPressedButton: PreviewKeyboardButton?
}
