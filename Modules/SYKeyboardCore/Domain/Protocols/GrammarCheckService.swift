//
//  GrammarCheckService.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

protocol GrammarCheckService: AnyObject {
    func check(text: String) async throws -> GrammarCheckResult
}
