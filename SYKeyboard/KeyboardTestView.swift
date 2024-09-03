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
            .textFieldStyle(.roundedBorder)
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
    }
}

#Preview {
    KeyboardTestView()
}
