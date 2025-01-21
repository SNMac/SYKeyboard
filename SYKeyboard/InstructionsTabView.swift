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
            InstructionsPageView(title: "커서 이동 방법", imageName: "instruction_move_cursor", subtitle: "강조된 버튼(흰색 버튼) 영역을 좌/우로 드래그")
            
            InstructionsPageView(title: "반복 입력 방법", imageName: "instruction_press_and_hold", subtitle: "강조된 버튼을 길게 누르기")
            
            InstructionsPageView(title: "한손 모드 변경 방법", imageName: "instruction_change_one_hand", subtitle: "자판 변경 버튼을 화살표 방향으로 드래그\nor 길게 누르기")
            
            InstructionsPageView(title: "숫자 자판 변경 방법", imageName: "instruction_change_number_view", subtitle: "자판 변경 버튼을 화살표 방향으로 드래그\n")
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        
        Button {
            dismiss()
        } label: {
            Text("닫기")
        }
        .frame(width: 40, height: 40)
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
    }
}

#Preview {
    InstructionsTabView()
}

