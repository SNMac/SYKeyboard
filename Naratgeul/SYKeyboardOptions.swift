//
//  SYKeyboardOptions.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import Foundation
import SwiftUI

enum KeyboardType {
  case hangul
  case symbol
}

final class SYKeyboardOptions: ObservableObject {
    @Published var current: KeyboardType = .hangul
    weak var delegate: SYKeyboardDelegate?
    var keyboardHeight: CGFloat
    var colorScheme: ColorScheme
    var needsInputModeSwitchKey: Bool
    var nextKeyboardAction: Selector
    
    init(
        delegate: SYKeyboardDelegate,
        keyboardHeight: CGFloat,
        colorScheme: ColorScheme, needsInputModeSwitchKey: Bool, nextKeyboardAction: Selector
    ) {
        self.delegate = delegate
        self.keyboardHeight = keyboardHeight
        self.colorScheme = colorScheme
        self.needsInputModeSwitchKey = needsInputModeSwitchKey
        self.nextKeyboardAction = nextKeyboardAction
    }
}
