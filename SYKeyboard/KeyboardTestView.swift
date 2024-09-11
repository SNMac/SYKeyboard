//
//  KeyboardTestView.swift
//  SYKeyboard
//
//  Created by 서동환 on 8/10/24.
//

import SwiftUI

struct KeyboardTestView: View {
    @State private var test = ""
    
    var body: some View {
        TextField("터치하여 키보드 테스트", text: $test)
            .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            .background(Color(UIColor.systemGray6).clipShape(RoundedRectangle(cornerRadius: 10)))
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
    }
}

#Preview {
    KeyboardTestView()
}
