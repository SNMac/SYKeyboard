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
            let keyRepeatPageTitle = String(localized: "길게 누르기 동작")
            let keyRepeatPageSubtitle = String(localized: "반복 입력 방법")
            let keyRepeatPageDescription = String(localized: "테두리가 강조된 버튼을 길게 누르기")
            InstructionsPageView(title: keyRepeatPageTitle,
                                 subtitle: keyRepeatPageSubtitle,
                                 image: .instructionLongPressKeyRepeat,
                                 description: keyRepeatPageDescription)
            
            let inputNumberPageTitle = String(localized: "길게 누르기 동작")
            let inputNumberPageSubtitle = String(localized: "숫자 입력 방법")
            let inputNumberPageDescription = String(localized: "테두리가 강조된 버튼을 길게 누르기\n(삭제 버튼은 반복 입력이 유지됩니다.)")
            InstructionsPageView(title: inputNumberPageTitle,
                                 subtitle: inputNumberPageSubtitle,
                                 image: .instructionLongPressInputNumber,
                                 description: inputNumberPageDescription)
            
            let moveCursorPageTitle = String(localized: "커서 이동 방법")
            let moveCursorPageDescription = String(localized: "테두리가 강조된 버튼(흰색 버튼) 영역을 좌/우로 드래그")
            InstructionsPageView(title: moveCursorPageTitle,
                                 image: .instructionMoveCursor,
                                 description: moveCursorPageDescription)
            
            let numericPageTitle = String(localized: "숫자 키패드 전환 방법")
            let numericPageDescription = String(localized: "'!#1', '한글' 또는 'ABC' 버튼을 화살표 방향으로 드래그")
            InstructionsPageView(title: numericPageTitle,
                                 image: .instructionChangeNumeric,
                                 description: numericPageDescription)
            
            let oneHandedPageTitle = String(localized: "한 손 키보드 변경 방법")
            let oneHandedPageDescription = String(localized: "'!#1', '한글' 또는 'ABC' 버튼을 위로 드래그 or 길게 누르기")
            InstructionsPageView(title: oneHandedPageTitle,
                                 image: .instructionChangeOneHanded,
                                 description: oneHandedPageDescription)
        }
        .tabViewStyle(.page)
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        
        Button {
            dismiss()
        } label: {
            Text("닫기")
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Preview

#Preview {
    InstructionsTabView()
}

