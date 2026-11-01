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
    
    /// 페이지 점 때문에 비워 두는 아래 여백. iPhone 13 mini 캡처에서 iOS 18.6·27.0 모두 오차 4pt 안으로 가운데에 오는 값이다
    private static let pageIndicatorClearance: CGFloat = 24
    
    // MARK: - Initializer
    
    init(title: String, subtitle: String = " ", image: ImageResource, description: String) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.description = description
    }
    
    // MARK: - Content
    
    var body: some View {
        VStack {
            VStack(spacing: 4) {
                Text(title)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineLimit(2, reservesSpace: true)
                Text(subtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }.frame(alignment: .top)
            
            Image(image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal)
                .padding(.vertical, 4)
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .lineLimit(3, reservesSpace: true)
        }
        // 페이지는 닫기 버튼 막대 아래부터 시트 아래까지를 받고, 아래쪽에는 페이지 점이 겹쳐 그려진다.
        // 점이 차지한 높이만큼 아래를 비워 내용이 닫기 버튼과 페이지 점 사이 가운데에 오게 한다
        .padding(.bottom, Self.pageIndicatorClearance)
    }
}

// MARK: - Preview

#Preview {
    InstructionsPageView(title: "한 손 키보드 변경 방법", subtitle: "", image: .instructionChangeOneHanded, description: "'!#1' 또는 '한글' 버튼을 위로 드래그하거나 길게 누르기")
}
