//
//  NaratgeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

struct NaratgeulView: View {
    @EnvironmentObject var state: NaratgeulState
    
    var body: some View {
        if #available(iOS 18, *) {
            switch state.currentInputType {
            case .hangeul:
                if state.currentKeyboardType == .twitter {
                    Swift6_TwitterHangeulView()
                } else {
                    Swift6_HangeulView()
                }
            case .symbol:
                if state.currentKeyboardType == .URL {
                    Swift6_URLSymbolView()
                } else if state.currentKeyboardType == .emailAddress {
                    Swift6_EmailSymbolView()
                } else if state.currentKeyboardType == .webSearch {
                    Swift6_WebSearchSymbolView()
                } else {
                    Swift6_SymbolView()
                }
            case .number:
                if state.currentKeyboardType == .numberPad {
                    Swift6_NumberPadView()
                } else {
                    Swift6_NumberView()
                }
            }
        } else {
            switch state.currentInputType {
            case .hangeul:
                if state.currentKeyboardType == .twitter {
                    TwitterHangeulView()
                } else {
                    HangeulView()
                }
            case .symbol:
                if state.currentKeyboardType == .URL {
                    URLSymbolView()
                } else if state.currentKeyboardType == .emailAddress {
                    EmailSymbolView()
                } else if state.currentKeyboardType == .webSearch {
                    WebSearchSymbolView()
                } else {
                    SymbolView()
                }
            case .number:
                if state.currentKeyboardType == .numberPad {
                    NumberPadView()
                } else if state.currentKeyboardType == .asciiCapableNumberPad {
                    NumberPadView()
                } else {
                    NumberView()
                }
            }
        }
    }
}

#Preview {
    NaratgeulView()
}
