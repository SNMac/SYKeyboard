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
        let placeHolderLocalStr = String(localized: "터치하여 키보드 테스트")
        SpecificLanguageTextFieldView(placeHolder: placeHolderLocalStr, language: "ko-KR", text: $text)
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            .background(Color(UIColor.systemGray6).clipShape(RoundedRectangle(cornerRadius: 8)))
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .frame(height: 36)
    }
}

#Preview {
    KeyboardTestView()
}
