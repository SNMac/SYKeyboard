//
//  NaratgeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

struct NaratgeulView: View {
    @EnvironmentObject var options: NaratgeulOptions
    
    var body: some View {
        if #available(iOS 18, *) {
            if options.current == .hangeul {
                Swift6_HangeulView()
            } else if options.current == .number {
                Swift6_NumberView()
            } else {
                Swift6_SymbolView()
            }
        } else {
            if options.current == .hangeul {
                HangeulView()
            } else if options.current == .number {
                NumberView()
            } else {
                SymbolView()
            }
        }
    }
}

#Preview {
    NaratgeulView()
}
