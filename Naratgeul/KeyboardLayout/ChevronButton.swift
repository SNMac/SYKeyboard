//
//  ChevronButton.swift
//  Naratgeul
//
//  Created by 서동환 on 11/7/24.
//

import SwiftUI

struct ChevronButton: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    @State var isPressing: Bool = false
    
    let isLeftHandMode: Bool
    var geometry: GeometryProxy
    
    var body: some View {
        Image(systemName: isLeftHandMode ? "chevron.compact.right" : "chevron.compact.left")
            .frame(width: geometry.size.width / 5.5, height: geometry.size.height)
            .font(.system(size: 36))
            .foregroundStyle(isPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
            .background(Color.white.opacity(0.001))
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged({ value in
                        if isLeftHandMode {  // 오른쪽에 화살표 표시됨
                            if value.location.x < geometry.size.width - geometry.size.width / 5.5 {
                                isPressing = false
                            } else {
                                isPressing = true
                            }
                        } else {  // 왼쪽에 화살표 표시됨
                            if value.location.x > geometry.size.width / 5.5 {
                                isPressing = false
                            } else {
                                isPressing = true
                            }
                        }
                    })
                    .onEnded({ value in
                        if isLeftHandMode {  // 오른쪽에 화살표 표시됨
                            if value.location.x < geometry.size.width - geometry.size.width / 5.5 {
                                isPressing = false
                            } else {
                                state.currentOneHandType = .center
                                currentOneHandType = OneHandType.center.rawValue
                                isPressing = false
                            }
                        } else {  // 왼쪽에 화살표 표시됨
                            if value.location.x > geometry.size.width / 5.5 {
                                isPressing = false
                            } else {
                                state.currentOneHandType = .center
                                currentOneHandType = OneHandType.center.rawValue
                                isPressing = false
                            }
                        }
                    })
            )
    }
}
