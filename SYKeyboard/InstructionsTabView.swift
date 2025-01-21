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
            let title1 = String(localized: "커서 이동 방법")
            let subtitle1 = String(localized: "테두리가 강조된 버튼(흰색 버튼) 영역을 좌/우로 드래그")
            InstructionsPageView(title: title1, imageName: "instruction_move_cursor", subtitle: subtitle1)
            
            let title2 = String(localized: "반복 입력 방법")
            let subtitle2 = String(localized: "테두리가 강조된 버튼을 길게 누르기")
            InstructionsPageView(title: title2, imageName: "instruction_press_and_hold", subtitle: subtitle2)
            
            let title3 = String(localized: "한 손 키보드 변경 방법")
            let subtitle3 = String(localized: "'!#1' 또는 '한글' 또는 '123' 버튼을 위로 드래그 or 길게 누르기")
            InstructionsPageView(title: title3, imageName: "instruction_change_one_hand", subtitle: subtitle3)
            
            let title4 = String(localized: "숫자 키보드 전환 방법")
            let subtitle4 = String(localized: "'!#1' 또는 '한글' 버튼을 화살표 방향으로 드래그")
            InstructionsPageView(title: title4, imageName: "instruction_change_number_view", subtitle: subtitle4)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        
        Button {
            dismiss()
        } label: {
            Text("닫기")
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
    }
}

#Preview {
    InstructionsTabView()
}

