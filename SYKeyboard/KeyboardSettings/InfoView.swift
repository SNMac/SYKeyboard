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
    @State private var itemSize = CGSize.zero
    
    private let subject = String(localized: "SY키보드 문의사항")
    private let messageHeaderStr = String(localized: "점선 아래에 내용을 입력해주세요. (상기된 정보가 정확하지 않을 경우 수정해 주세요!)")
    
    var body: some View {
        Button {
            isShowingInstructions = true
        } label: {
            HStack {
                Image(systemName: "text.page")
                    .background(GeometryReader {
                        Color.clear.preference(key: ItemSize.self,
                                               value: $0.frame(in: .local).size)
                    })
                    .frame(width: itemSize.width, height: itemSize.height)
                    .onPreferenceChange(ItemSize.self) {
                        itemSize = $0
                    }
                Text("키보드 사용 안내")
            }
        }
        
        Button {
            let email = SupportEmail(toAddress: "seosdh4@gmail.com", subject: self.subject, messageHeader: self.messageHeaderStr)
            email.send(openURL: self.openURL)
        } label: {
            HStack {
                Image(systemName: "questionmark.bubble")
                    .background(GeometryReader {
                        Color.clear.preference(key: ItemSize.self,
                                               value: $0.frame(in: .local).size)
                    })
                    .frame(width: itemSize.width, height: itemSize.height)
                    .onPreferenceChange(ItemSize.self) {
                        itemSize = $0
                    }
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
                    .background(GeometryReader {
                        Color.clear.preference(key: ItemSize.self,
                                               value: $0.frame(in: .local).size)
                    })
                    .frame(width: itemSize.width, height: itemSize.height)
                    .onPreferenceChange(ItemSize.self) {
                        itemSize = $0
                    }
                Text("리뷰 및 별점 주기")
            }
        }
        
        HStack {
            Text("버전")
            Spacer()
            Text(Bundle.appVersion ?? "Unknown")
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
