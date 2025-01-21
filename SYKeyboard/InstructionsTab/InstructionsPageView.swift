//
//  InstructionsPageView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/21/25.
//

import SwiftUI

struct InstructionsPageView: View {
    let title: String
    let imageName: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding()
        }
    }
}

#Preview {
    InstructionsPageView(title: "커서 이동 방법", imageName: "instruction_moveCursor")
}
