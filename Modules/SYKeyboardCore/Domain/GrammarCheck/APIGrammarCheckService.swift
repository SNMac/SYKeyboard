//
//  APIGrammarCheckService.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

import Foundation

final class APIGrammarCheckService: GrammarCheckProvider {
    
    init() {}
    
    // MARK: - GrammarCheckProvider Methods
    
    func check(text: String) async throws -> GrammarCheckResult {
        // TODO: 맞춤법 검사 API 연동 (네이버/부산대 등 추후 결정)
        fatalError("Not implemented yet")
    }
}
