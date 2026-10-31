//
//  SheetCloseButton.swift
//  SYKeyboard
//
//  Created by Claude on 10/31/26.
//

import SwiftUI

/// 시트 툴바에 두는 닫기 버튼.
///
/// iOS 26부터는 시스템 닫기 버튼(X)으로 다른 시트와 모양을 맞추고, 그 전에는 '닫기' 글자 버튼을 쓴다.
/// X는 이미지 항목이라 iPhone Duo 바깥 화면에서 세로 바로 들어간다. 글자 항목은 가로 바에만 놓인다
struct SheetCloseButton: View {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close, action: action)
        } else {
            Button("닫기", action: action)
        }
    }
}
