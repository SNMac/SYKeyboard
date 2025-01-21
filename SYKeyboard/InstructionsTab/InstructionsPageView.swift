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
    InstructionsPageView(title: "한손 모드 변경 방법", imageName: "instruction_change_one_hand", subtitle: "자판 변경 버튼을 화살표 방향으로 드래그\nor 길게 누르기")
}
