//
//  PreviewSYKeyboardOptions.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
//

import Foundation

enum PreviewKeyboardType {
    case hangeul
    case number
    case symbol
}

final class PreviewNaratgeulOptions: ObservableObject {
    @Published var current: PreviewKeyboardType = .hangeul
    @Published var nowSymbolPage: Int = 0
    @Published var totalSymbolPage: Int = 0
    var nowPressedButton: PreviewNaratgeulButton?
    var swift6_nowPressedButton: Swift6_PreviewNaratgeulButton?
}
