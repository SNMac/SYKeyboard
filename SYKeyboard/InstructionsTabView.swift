//
//  InstructionsTabView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/21/25.
//

import SwiftUI

struct InstructionsTabView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Contents
    
    var body: some View {
        TabView {
            let keyRepeatPageTitleLocalStr = String(localized: "반복 입력 방법")
            let keyRepeatPageSubtitleLocalStr = String(localized: "테두리가 강조된 버튼을 길게 누르기")
            InstructionsPageView(title: keyRepeatPageTitleLocalStr, image: .instructionKeyRepeat, subtitle: keyRepeatPageSubtitleLocalStr)
            
            let moveCursorPageTitleLocalStr = String(localized: "커서 이동 방법")
            let moveCursorPageSubtitleLocalStr = String(localized: "테두리가 강조된 버튼(흰색 버튼) 영역을 좌/우로 드래그")
            InstructionsPageView(title: moveCursorPageTitleLocalStr, image: .instructionMoveCursor, subtitle: moveCursorPageSubtitleLocalStr)
            
            let numericPageTitleLocalStr = String(localized: "숫자 키패드 전환 방법")
            let numericPageSubtitleLocalStr = String(localized: "'!#1' 또는 '한글' 버튼을 화살표 방향으로 드래그")
            InstructionsPageView(title: numericPageTitleLocalStr, image: .instructionChangeNumeric, subtitle: numericPageSubtitleLocalStr)
            
            let oneHandedPageTitleLocalStr = String(localized: "한 손 키보드 변경 방법")
            let oneHandedPageSubtitleLocalStr = String(localized: "'!#1' 또는 '한글' 버튼을 위로 드래그 or 길게 누르기")
            InstructionsPageView(title: oneHandedPageTitleLocalStr, image: .instructionChangeOneHanded, subtitle: oneHandedPageSubtitleLocalStr)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        
        Button {
            dismiss()
        } label: {
            Text("닫기")
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
    }
}

// MARK: - Preview

#Preview {
    InstructionsTabView()
}

