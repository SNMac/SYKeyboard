//
//  TopAutocomplete.swift
//  Naratgeul
//
//  Created by Sunghyun Cho on 1/15/23.
//  Edited by 서동환 on 10/10/24.
//

import Foundation

class TopAutocomplete: ObservableObject {
    @Published var list: [String] = []
    var action: (String) -> Void
    
    init(action: @escaping (String) -> Void) {
        self.action = action
    }
}

