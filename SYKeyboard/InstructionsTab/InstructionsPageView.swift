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
    let subtitle: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
            Image(imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding()
            Text(subtitle)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    InstructionsPageView(title: "커서 이동 방법", imageName: "instruction_move_cursor", subtitle: "흰색 버튼 영역 드래그 ➡️ 커서 이동")
}
