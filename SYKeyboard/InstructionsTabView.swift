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
            InstructionsPageView(title: "커서 이동 방법", imageName: "instruction_moveCursor")
            
            InstructionsPageView(title: "반복 입력 방법", imageName: "instruction_pressAndHold")
            
            InstructionsPageView(title: "한손 키보드 변경 방법", imageName: "instruction_changeOneHand")
            
            InstructionsPageView(title: "숫자 자판 변경 방법", imageName: "instruction_changeNumberView")
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        
        Button {
            dismiss()
        } label: {
            Text("닫기")
        }
        .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
    }
}

#Preview {
    InstructionsTabView()
}

