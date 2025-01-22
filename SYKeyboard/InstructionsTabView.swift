//
//  InstructionsTabView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/21/25.
//

import SwiftUI

struct InstructionsTabView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            let firstPageTitleLocalStr = String(localized: "커서 이동 방법")
            let firstPageSubtitleLocalStr = String(localized: "테두리가 강조된 버튼(흰색 버튼) 영역을 좌/우로 드래그")
            InstructionsPageView(title: firstPageTitleLocalStr, imageName: "instruction_move_cursor", subtitle: firstPageSubtitleLocalStr)
            
            let secondPageTitleLocalStr = String(localized: "반복 입력 방법")
            let secondPageSubtitleLocalStr = String(localized: "테두리가 강조된 버튼을 길게 누르기")
            InstructionsPageView(title: secondPageTitleLocalStr, imageName: "instruction_press_and_hold", subtitle: secondPageSubtitleLocalStr)
            
            let thirdPageTitleLocalStr = String(localized: "한 손 키보드 변경 방법")
            let thirdPageSubtitleLocalStr = String(localized: "'!#1' 또는 '한글' 또는 '123' 버튼을 위로 드래그 or 길게 누르기")
            InstructionsPageView(title: thirdPageTitleLocalStr, imageName: "instruction_change_one_hand", subtitle: thirdPageSubtitleLocalStr)
            
            let fourthPageTitleLocalStr = String(localized: "숫자 패드 전환 방법")
            let fourthPageSubtitleLocalStr = String(localized: "'!#1' 또는 '한글' 버튼을 화살표 방향으로 드래그")
            InstructionsPageView(title: fourthPageTitleLocalStr, imageName: "instruction_change_number_view", subtitle: fourthPageSubtitleLocalStr)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        
        Button {
            dismiss()
        } label: {
            Text("닫기")
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0))
    }
}

#Preview {
    InstructionsTabView()
}

