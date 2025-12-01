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
    private let subtitle: String
    private let image: ImageResource
    private let description: String
    
    // MARK: - Initializer
    
    init(title: String, subtitle: String = " ", image: ImageResource, description: String) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.description = description
    }
    
    // MARK: - Contents
    
    var body: some View {
        VStack {
            VStack(spacing: 4) {
                Text(title)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                Text(subtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }.frame(height: 80, alignment: .top)
            
            Image(image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(height: 80, alignment: .top)
        }
    }
}

// MARK: - Preview

#Preview {
    InstructionsPageView(title: "한 손 키보드 변경 방법", subtitle: "", image: .instructionChangeOneHanded, description: "'!#1' 또는 '한글' 버튼을 위로 드래그 or 길게 누르기")
}
