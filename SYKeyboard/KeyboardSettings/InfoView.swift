//
//  InfoView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/12/24.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.openURL) private var openURL
    @State private var isShowingInstructions = false
    
    var body: some View {
        Button {
            isShowingInstructions = true
        } label: {
            HStack {
                Image(systemName: "questionmark.text.page")
                Text("키보드 사용 안내 보기")
            }
        }
        
        Button {
            // TODO: 문의하기 뷰 만들기
        } label: {
            HStack {
                Image(systemName: "questionmark.bubble")
                Text("문의하기")
            }
        }

        Button {
            let url = "https://apps.apple.com/app/id6670792957?action=write-review"
            guard let writeReviewURL = URL(string: url) else {
                fatalError("Expected a valid URL")
            }
            
            openURL(writeReviewURL)
        } label: {
            HStack {
                Image(systemName: "pencil.line")
                Text("리뷰 및 별점 주기")
            }
        }
        
        HStack {
            Text("버전")
            Spacer()
            Text((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
                .foregroundStyle(.gray)
        }
        .sheet(isPresented: $isShowingInstructions) {
            InstructionsTabView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    InfoView()
}
