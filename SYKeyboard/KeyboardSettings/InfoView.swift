//
//  InfoView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/12/24.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        HStack {
            Text("버전")
            Spacer()
            Text((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
                .foregroundStyle(.gray)
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

    }
}

#Preview {
    InfoView()
}
