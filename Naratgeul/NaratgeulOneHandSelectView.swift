//
//  NaratgeulOneHandSelectView.swift
//  Naratgeul
//
//  Created by 서동환 on 10/30/24.
//

import SwiftUI

struct NaratgeulOneHandSelectView: View {
    @EnvironmentObject var state: NaratgeulState
    
    let activeFontSize: Double = 32
    let otherFontSize: Double = 16
    
    var body: some View {
        HStack(spacing: 1) {
            if state.selectedOneHandType == .left {
                Image(systemName: "keyboard.onehanded.left.fill")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Image(systemName: "keyboard")
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                
                Image(systemName: "keyboard.onehanded.right")
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                
            } else if state.selectedOneHandType == .center {
                Image(systemName: "keyboard.onehanded.left")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                
                Image(systemName: "keyboard.fill")
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Image(systemName: "keyboard.onehanded.right")
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                
            } else if state.selectedOneHandType == .right {
                Image(systemName: "keyboard.onehanded.left")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                
                Image(systemName: "keyboard.fill")
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                
                Image(systemName: "keyboard.onehanded.right.fill")
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: 170, height: 60)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NaratgeulOneHandSelectView()
}
