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
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
            Image(imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding()
            Text(subtitle)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    InstructionsPageView(title: "한 손 키보드 변경 방법", imageName: "instruction_change_one_hand", subtitle: "자판 변경 버튼을 화살표 방향으로 드래그 or 길게 누르기")
}
