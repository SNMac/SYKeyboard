//
//  GrammarCheckEngine.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

import Foundation

final class GrammarCheckEngine: GrammarCheckService {
    
    // MARK: - Properties
    
    enum Error: Swift.Error {
        case emptyText
    }
    
    private let service: GrammarCheckProvider
    
    // MARK: - Initializer
    
    /// Foundation Models 지원 여부와 사용자 설정에 따라 적절한 서비스를 선택합니다.
    init(preferredMethod: GrammarCheckMethod) {
        if #available(iOS 26, *),
            preferredMethod == .foundationModels {
            self.service = FoundationModelsGrammarCheckService()
        } else {
            self.service = APIGrammarCheckService()
        }
    }
    
    // MARK: - GrammarCheckService Methods
    
    func check(text: String) async throws -> GrammarCheckResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw Error.emptyText
        }
        return try await service.check(text: trimmed)
    }
}
