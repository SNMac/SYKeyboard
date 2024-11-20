//
//  PreviewNaratgeulState.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
//

import Foundation

enum PreviewOneHandType {
    case left
    case center
    case right
}

final class PreviewNaratgeulState: ObservableObject {
    @Published var currentOneHandType: PreviewOneHandType = .center
    
    var nowPressedButton: PreviewNaratgeulButton?
    var ios18_nowPressedButton: iOS18_PreviewNaratgeulButton?
}
