//
//  KeyboardTestView.swift
//  SYKeyboard
//
//  Created by 서동환 on 8/10/24.
//

import SwiftUI

struct KeyboardTestView: View {
    @State private var text = ""
    
    var body: some View {
        SpecificLanguageTextFieldView(placeHolder: "터치하여 키보드 테스트", text: $text, language: "ko-KR")
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            .background(Color(UIColor.systemGray6).clipShape(RoundedRectangle(cornerRadius: 8)))
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .frame(height: 30)
    }
}

#Preview {
    KeyboardTestView()
}
