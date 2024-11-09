//
//  NaratgeulInputTypeSelectView.swift
//  Naratgeul
//
//  Created by 서동환 on 10/9/24.
//

import SwiftUI

struct NaratgeulInputTypeSelectView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var state: NaratgeulState
    
    let fontSize: Double = 16
    
    var body: some View {
        HStack(spacing: 5) {
            if state.currentInputType == .hangeul {
                Text("123")
                    .monospaced()
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
                
                Text("!#1")
                    .monospaced()
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .symbol ? Color.blue : Color.clear))
                
                Image(systemName: "x.square")
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .hangeul ? Color.blue : Color.clear))
                
                
            } else if state.currentInputType == .number {
                Text("!#1")
                    .monospaced()
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .symbol ? Color.blue : Color.clear))
                
                Text("한글")
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .hangeul ? Color.blue : Color.clear))
                
                Image(systemName: "x.square")
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
                
                
            } else if state.currentInputType == .symbol {
                Image(systemName: "x.square")
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .symbol ? Color.blue : Color.clear))
                
                Text("한글")
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .hangeul ? Color.blue : Color.clear))
                
                Text("123")
                    .monospaced()
                    .font(.system(size: fontSize))
                    .frame(width: 50, height: 50)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
            }
        }
        .frame(width: 170, height: 60)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NaratgeulInputTypeSelectView()
}
