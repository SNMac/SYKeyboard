//
//  PreviewSYKeyboardOptions.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
//

import Foundation

enum PreviewKeyboardType {
  case hangul
  case symbol
}

final class PreviewSYKeyboardOptions: ObservableObject {
    @Published var current: PreviewKeyboardType = .hangul
    var curPressedButton: PreviewSYKeyboardButton?
}
