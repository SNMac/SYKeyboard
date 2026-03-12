//
//  SuggestionService.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

import UIKit

/// 자동완성 후보 조회, 텍스트 대치, 대치 복구를 제공하는 서비스 프로토콜
///
/// SuggestionBar에 표시할 후보 관리, 스페이스 입력 시 텍스트 대치,
/// 삭제 시 대치 복구 기능을 통합적으로 정의합니다.
/// `isEnabled`를 통해 연산 자체를 비활성화할 수 있습니다.
///
/// ## 채택 구현체
/// - `SuggestionController`: `UILexicon` + `UITextChecker` + n-gram을 조합한 기본 구현
///
/// ## 동작 흐름
/// 1. **입력 중**: `updateSuggestions(contextBeforeInput:)`로 후보 갱신
/// 2. **후보 탭**: `selectSuggestion(at:contextBeforeInput:)`로 현재 단어 교체
/// 3. **스페이스**: `attemptTextReplacement(contextBeforeInput:)`로 텍스트 대치 수행, `recordWord(_:)`로 n-gram 기록
/// 4. **삭제**: `attemptRestoreReplacement(contextBeforeInput:)`로 대치 복구
/// 5. **리턴**: `endSentence()`로 n-gram 문장 버퍼 초기화
/// 6. **기타 키 입력**: `clearIgnoredShortcut()`으로 재대치 방지 상태 초기화
protocol SuggestionService: AnyObject {
    
    // MARK: - Properties
    
    /// 후보 업데이트 이벤트를 수신하는 델리게이트
    var delegate: SuggestionControllerDelegate? { get set }
    
    /// 자동완성 활성화 여부
    ///
    /// `false`로 설정하면 후보 연산을 건너뛰고 현재 후보를 초기화합니다.
    var isEnabled: Bool { get set }
    
    // MARK: - Lexicon
    
    /// `UIInputViewController`로부터 `UILexicon`을 로드합니다.
    ///
    /// `viewDidLoad` 시점에 호출하여 Lexicon 데이터를 준비합니다.
    ///
    /// - Parameter inputViewController: 현재 키보드의 `UIInputViewController`
    func loadLexicon(from inputViewController: UIInputViewController)
    
    // MARK: - Suggestions
    
    /// 현재 입력 컨텍스트를 기반으로 후보를 갱신합니다.
    ///
    /// 갱신 결과는 `delegate`의
    /// `SuggestionControllerDelegate/suggestionController(_:didUpdateCurrentWord:suggestions:)`를 통해 전달됩니다.
    ///
    /// 입력 중일 때는 button1에 현재 단어, button2~3에 자동완성 후보를 표시하고,
    /// 입력이 없거나 마지막 문자가 공백이면 n-gram 기반 다음 단어 예측을 표시합니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트 (`documentContextBeforeInput`)
    func updateSuggestions(contextBeforeInput: String?)
    
    /// 모든 후보를 초기화합니다.
    func clearSuggestions()
    
    /// 사용자가 후보를 선택했을 때 호출합니다.
    ///
    /// 현재 입력 중인 단어를 선택한 후보로 교체하기 위한 정보를 반환합니다.
    ///
    /// - Parameters:
    ///   - index: 선택된 후보의 인덱스 (0~1)
    ///   - contextBeforeInput: 커서 앞의 텍스트
    /// - Returns: 삭제할 글자 수와 삽입할 텍스트의 튜플, 유효하지 않으면 `nil`
    func selectSuggestion(at index: Int, contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)?
    
    /// n-gram 모드에서 특정 인덱스의 후보 텍스트를 반환합니다.
    func nGramSuggestionText(at index: Int) -> String?
    
    // MARK: - Learning
    
    /// 단어를 시스템 사전에 학습시킵니다.
    ///
    /// 사용자가 현재 입력 단어를 확정했을 때 호출하여
    /// 이후 `UITextChecker` 후보에 반영합니다.
    ///
    /// - Parameter word: 학습할 단어
    func learnWord(_ word: String)
    
    // MARK: - N-Gram Recording
    
    /// 단어를 n-gram 엔진에 기록합니다.
    ///
    /// 스페이스 입력 시 직전 단어를 전달하여 호출합니다.
    ///
    /// - Parameter word: 기록할 단어
    func recordWord(_ word: String)
    
    /// n-gram 문장 버퍼를 초기화합니다.
    ///
    /// 리턴 키 입력 시 호출합니다.
    func endSentence()
    
    /// n-gram 데이터를 디스크에 저장합니다.
    ///
    /// 키보드가 비활성화되기 전에 호출합니다.
    func saveNGramData()
    
    // MARK: - Text Replacement
    
    /// 스페이스 입력 시 텍스트 대치를 시도합니다.
    ///
    /// 커서 앞 텍스트의 끝부분이 `UILexicon`의 `userInput`과 일치하면
    /// 해당 `documentText`로 교체합니다.
    /// 방금 복구된 단축어와 동일하면 대치를 건너뜁니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트
    /// - Returns: 대치 수행 정보. 대치가 불필요하면 `nil`
    func attemptTextReplacement(contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)?
    
    /// 삭제 시 방금 수행된 텍스트 대치를 복구합니다.
    ///
    /// 커서 앞 텍스트의 끝부분이 이전에 대치된 `documentText`와 일치하면
    /// 원래 `userInput`으로 되돌립니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트
    /// - Returns: 복구 수행 정보. 복구할 대상이 없으면 `nil`
    func attemptRestoreReplacement(contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)?
    
    // MARK: - State Management
    
    /// 스페이스 이외의 키 입력 시 호출하여 재대치 방지 상태를 초기화합니다.
    func clearIgnoredShortcut()
    
    /// 대치 이력을 모두 초기화합니다.
    func clearReplacementHistory()
}
