//
//  SuggestionService.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

import UIKit

/// 자동완성 후보 조회, 텍스트 대치, 대치 복구를 제공하는 서비스 프로토콜
protocol SuggestionService: AnyObject {
    
    // MARK: - Properties
    
    var delegate: SuggestionControllerDelegate? { get set }
    var isEnabled: Bool { get set }
    
    // MARK: - Lexicon
    
    func loadLexicon(from inputViewController: UIInputViewController)
    
    // MARK: - Suggestions
    
    func updateSuggestions(contextBeforeInput: String?)
    func clearSuggestions()
    func selectSuggestion(at index: Int, contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)?
    
    // MARK: - Text Replacement
    
    func attemptTextReplacement(contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)?
    func attemptRestoreReplacement(contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)?
    
    // MARK: - State Management
    
    func clearIgnoredShortcut()
    func clearReplacementHistory()
}
