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
            switch options.currentInputType {
            case .hangeul:
                if options.currentKeyboardType == .twitter {
                    Swift6_TwitterHangeulView()
                } else {
                    Swift6_HangeulView()
                }
            case .symbol:
                if options.currentKeyboardType == .URL {
                    Swift6_URLSymbolView()
                } else if options.currentKeyboardType == .emailAddress {
                    Swift6_EmailSymbolView()
                } else if options.currentKeyboardType == .webSearch {
                    Swift6_WebSearchSymbolView()
                } else {
                    Swift6_SymbolView()
                }
            case .number:
                if options.currentKeyboardType == .numberPad {
                    Swift6_NumberPadView()
                } else {
                    Swift6_NumberView()
                }
            }
        } else {
            switch options.currentInputType {
            case .hangeul:
                if options.currentKeyboardType == .twitter {
                    TwitterHangeulView()
                } else {
                    HangeulView()
                }
            case .symbol:
                if options.currentKeyboardType == .URL {
                    URLSymbolView()
                } else if options.currentKeyboardType == .emailAddress {
                    EmailSymbolView()
                } else if options.currentKeyboardType == .webSearch {
                    WebSearchSymbolView()
                } else {
                    SymbolView()
                }
            case .number:
                if options.currentKeyboardType == .numberPad {
                    NumberPadView()
                } else if options.currentKeyboardType == .asciiCapableNumberPad {
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
