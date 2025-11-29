//
//  InstructionsPageView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/21/25.
//

import SwiftUI

struct InstructionsPageView: View {
    
    // MARK: - Properties
    
    private let title: String
    private let image: ImageResource
    private let subtitle: String
    
    // MARK: - Initializer
    
    init(title: String, image: ImageResource, subtitle: String) {
        self.title = title
        self.image = image
        self.subtitle = subtitle
    }
    
    // MARK: - Contents
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
                .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
            Image(image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding()
            Text(subtitle)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
                .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
        }
    }
}

// MARK: - Preview

#Preview {
    InstructionsPageView(title: "한 손 키보드 변경 방법", image: .instructionChangeOneHanded, subtitle: "'!#1' 또는 '한글' 버튼을 위로 드래그 or 길게 누르기")
}
