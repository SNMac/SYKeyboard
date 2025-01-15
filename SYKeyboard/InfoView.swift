//
//  InfoView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/12/24.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        HStack {
            Text("버전")
            Spacer()
            Text((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
                .foregroundStyle(.gray)
        }
        Button {
            if let writeReviewURL = URL(string: "https://apps.apple.com/app/sy키보드/id6670792957?action=write-review") {
                UIApplication.shared.open(writeReviewURL)
            }
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
