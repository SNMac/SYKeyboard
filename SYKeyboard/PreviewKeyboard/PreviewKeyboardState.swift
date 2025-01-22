//
//  PreviewKeyboardState.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/10/25.
//

import SwiftUI

enum PreviewOneHandKeyboard: Int {
    case left
    case center
    case right
}

final class PreviewKeyboardState: ObservableObject {
    @Published var currentOneHandKeyboard: PreviewOneHandKeyboard = .center
    
    var nowPressedButton: PreviewKeyboardButton?
}
