//
//  AutocompleteButton.swift
//  Naratgeul
//
//  Created by 서동환 on 10/10/24.
//

import SwiftUI

struct Swift6_AutocompleteButton: View {
    let text: String?
    let action: () -> Void
    
    @State var isPressed: Bool = false
    
    var body: some View {
        Text(text ?? "")
//            .frame(idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: 40, alignment: .center)
            .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, idealHeight: 40, maxHeight: .infinity, alignment: .center)
            .foregroundStyle(Color(uiColor: UIColor.label))
            .background(isPressed ? .black : Color.white.opacity(0.001))
            .onLongPressGesture(minimumDuration: 0) {
            } onPressingChanged: { isPressing in
                if isPressing {
                    // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                    isPressed = true
                    print("onLongPressGesture()->onPressingChanged: pressing")
                    action()
                } else {
                    // 버튼 뗐을 때
                    print("onLongPressGesture()->onPressingChanged: released")
                    isPressed = false
                }
            }
    }
}
