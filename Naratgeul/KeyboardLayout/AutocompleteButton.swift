//
//  AutocompleteButton.swift
//  Naratgeul
//
//  Created by 서동환 on 10/10/24.
//

import SwiftUI

struct AutocompleteButton: View {
    let text: String?
    let action: () -> Void
    
    var body: some View {
        Button(
            action: action,
            label: {
                Text(text ?? "")
                    .frame(idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: 40, alignment: .center)
                    .foregroundColor(Color(uiColor: UIColor.label))
            }
        )
        .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: 40, alignment: .center)
        .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, idealHeight: 40, maxHeight: .infinity, alignment: .center)
    }
}
