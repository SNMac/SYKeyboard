//
//  InfoView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/12/24.
//

import SwiftUI
import OSLog

import FirebaseAnalytics

struct InfoView: View {
    
    // MARK: - Properties
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: "SupportEmail"))
    
    @Environment(\.openURL) private var openURL
    @State private var isShowingInstructions = false
    
    // MARK: - Contents
    
    var body: some View {
        Button {
            Analytics.logEvent("open_keyboard_instructions", parameters: [
                "view": "info"
            ])
            
            isShowingInstructions = true
        } label: {
            HStack {
                Image(.textPage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("키보드 사용 안내")
            }
        }
        
        Button {
            Analytics.logEvent("open_email_inquiry", parameters: [
                "view": "info"
            ])
            
            let address = Bundle.main.infoDictionary?["DeveloperEmail"] as! String
            let subjectLocalStr = String(localized: "SY키보드 문의 사항")
            let messageHeaderLocalStr = String(localized: "점선 아래에 내용을 입력해 주세요. (상기된 정보가 정확하지 않을 경우 수정해 주세요!)")
            
            let emailModel = SupportEmailModel(toAddress: address, subject: subjectLocalStr, messageHeader: messageHeaderLocalStr)
            guard let url = emailModel.makeURL() else { return }
            openURL(url) { accepted in
                if !accepted {
                    Self.logger.debug(
                    """
                    This device does not support email
                    --------------------------------------
                    \(emailModel.body)
                    """)
                }
            }
        } label: {
            HStack {
                Image(.questionmarkBubble)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("문의하기")
            }
        }
        
        Button {
            Analytics.logEvent("open_review", parameters: [
                "view": "info"
            ])
            
            let reviewURLString = "https://apps.apple.com/app/id6670792957?action=write-review"
            guard let url = URL(string: reviewURLString) else {
                assertionFailure("Expected a valid URL")
                return
            }
            openURL(url)
        } label: {
            HStack {
                Image(.pencilLine)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
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
                .presentationDetents([.fraction(0.8)])
        }
    }
}

// MARK: - Preview

#Preview {
    InfoView()
}
