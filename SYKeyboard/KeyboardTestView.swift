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
        Form {
            TextField("키보드를 테스트하세요", text: $test)
        }
    }
}

#Preview {
    KeyboardTestView()
}
