//
//  GrammarCheckProvider.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

struct GrammarCheckResult {
    /// 교정된 전체 텍스트
    let correctedText: String
    /// 교정 사항이 있었는지 여부
    let hasCorrections: Bool
}

protocol GrammarCheckProvider {
    func check(text: String) async throws -> GrammarCheckResult
}
