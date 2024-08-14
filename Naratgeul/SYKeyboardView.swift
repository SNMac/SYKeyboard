//
//  SYKeyboardView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI



struct SYKeyboardView: View {
    @EnvironmentObject var options: SYKeyboardOptions
    
    var body: some View {
        if options.current == .hangul {
            SYKeyboardHangulView()
        } else if options.current == .symbol {
            SYKeyboardSymbolView()
        }
    }
}

#Preview {
    SYKeyboardView()
}
