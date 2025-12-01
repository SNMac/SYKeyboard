//
//  KeyboardTestView.swift
//  SYKeyboard
//
//  Created by 서동환 on 8/10/24.
//

import SwiftUI

struct KeyboardTestView: View {
    
    // MARK: - Properties
    
    @State private var text = ""
    
    // MARK: - Contents
    
    var body: some View {
        TextField("터치하여 키보드 테스트", text: $text, axis: .vertical)
            .font(.system(size: 17))
            .lineLimit(1...4)
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            .background {
                Color(.systemGray6)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
    }
}

// MARK: - Preview

#Preview {
    KeyboardTestView()
}
