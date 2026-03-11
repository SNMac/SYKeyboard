//
//  FoundationModelsGrammarCheckService.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

import Foundation
import FoundationModels

@available(iOS 26, *)
final class FoundationModelsGrammarCheckService: GrammarCheckProvider {
    
    // MARK: - Properties
    
    enum Error: Swift.Error {
        case modelUnavailable
    }
    
    @Generable(description: "Grammar and spelling check result for the given text")
    struct GrammarCheckResponse {
        /// 교정된 텍스트
        @Guide(description: "The corrected full text. If no errors found, return the original text as-is.")
        let correctedText: String
        /// 교정 사항이 있었는지 여부
        @Guide(description: "Whether any corrections were made. true if the text was modified, false if no errors were found.")
        let hasCorrections: Bool
    }
    
    private let instructions = """
    You are a Korean and English grammar and spelling expert.
    Correct any spelling, spacing, and grammar errors in the user's text.
    
    Rules:
    - Only fix spelling, spacing, and grammar. Do not change meaning or style.
    - If the text has no errors, return it unchanged with hasCorrections set to false.
    - If the text has errors, return the corrected text with hasCorrections set to true.
    """
    
    // MARK: - GrammarCheckProvider Methods
    
    func check(text: String) async throws -> GrammarCheckResult {
        guard SystemLanguageModel.default.isAvailable else {
            throw Error.modelUnavailable
        }
        
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: text, generating: GrammarCheckResponse.self)
        
        return GrammarCheckResult(
            correctedText: response.content.correctedText,
            hasCorrections: response.content.hasCorrections
        )
    }
}
