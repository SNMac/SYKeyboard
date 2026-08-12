//
//  SuggestionService.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

import UIKit

enum MathResultSuggestionAction: Equatable {
    case confirmOriginal
    case insertResult(String)
    case replaceExpression(deleteCount: Int, insertText: String)
    case replaceSelection(String)
}

/// 자동완성 후보 조회, 텍스트 대치, 대치 복구를 제공하는 서비스 프로토콜
///
/// SuggestionBar에 표시할 후보 관리, 스페이스 입력 시 텍스트 대치,
/// 삭제 시 대치 복구 기능을 통합적으로 정의합니다.
///
/// ## 활성화 제어
/// - `isPredictiveTextEnabled`: 사용자 설정. `false`이면 자동완성 관련 엔진을 비활성화합니다.
/// - `isTextReplacementEnabled`: 사용자 설정. `false`이면 텍스트 대치 기능을 비활성화합니다.
/// - `isSuspended`: 텍스트 필드별 일시적 비활성화 (`autocorrectionType == .no` 등).
///   엔진을 해제하지 않고 조회·기록만 건너뜁니다.
///
/// ## 채택 구현체
/// - `SuggestionController`: `UILexicon` + `UITextChecker` + n-gram을 조합한 기본 구현
///
/// ## 동작 흐름
/// 1. **입력 중**: `updateSuggestions(for baseText:)`로 후보 갱신
/// 2. **후보 탭**: `selectSuggestion(at:inputBuffer:)`로 현재 단어 교체
/// 3. **스페이스**: `attemptTextReplacement(inputBuffer:)`로 텍스트 대치 수행, `recordWord(_:)`로 n-gram 기록
/// 4. **삭제**: `attemptRestoreReplacement(inputBuffer:documentContextBeforeInput:selectedText:)`로 대치 복구
/// 5. **리턴**: `endSentence()`로 n-gram 문장 버퍼 초기화
/// 6. **기타 키 입력**: `clearIgnoredShortcut()`으로 재대치 방지 상태 초기화
protocol SuggestionService: AnyObject {

    // MARK: - Properties

    /// 후보 업데이트 이벤트를 수신하는 델리게이트
    var delegate: SuggestionControllerDelegate? { get set }

    /// 자동완성 사용자 설정
    ///
    /// `false`로 설정하면 자동완성 관련 엔진(`UITextChecker`, n-gram)을 비활성화합니다.
    /// `true`로 복구해도 엔진은 즉시 생성하지 않고 준비 API에서 생성합니다.
    var isPredictiveTextEnabled: Bool { get set }

    /// 텍스트 대치 사용자 설정
    ///
    /// `false`로 설정하면 텍스트 대치 기능을 비활성화합니다.
    var isTextReplacementEnabled: Bool { get set }

    /// 수식 결과 후보 표시 사용자 설정
    ///
    /// `false`로 설정하면 `=` 입력 시 계산 결과 후보를 표시하지 않습니다.
    var isShowMathResultsEnabled: Bool { get set }

    /// 텍스트 필드별 일시적 비활성화
    ///
    /// `autocorrectionType == .no`인 텍스트 필드 등에서 `true`로 설정합니다.
    /// 엔진을 해제하지 않고 조회·기록만 건너뜁니다.
    var isSuspended: Bool { get set }

    /// 현재 SuggestionBar의 표시 모드
    var currentMode: SuggestionMode { get }

    /// 예측 엔진에서 사용할 언어를 전환합니다.
    func updateLanguage(to language: String)

    // MARK: - Lexicon

    /// 자동완성 예측 엔진을 필요한 시점에 준비합니다.
    func preparePredictiveEnginesIfNeeded()

    /// `UILexicon` 기반 엔진을 필요한 시점에 준비합니다.
    func prepareLexiconEngineIfNeeded()

    /// `UIInputViewController`로부터 `UILexicon`을 로드합니다.
    ///
    /// 첫 표시 이후 또는 필요한 시점에 호출하여 Lexicon 데이터를 준비합니다.
    ///
    /// - Parameter inputViewController: 현재 키보드의 `UIInputViewController`
    func loadLexicon(from inputViewController: UIInputViewController)

    // MARK: - Suggestions

    /// 현재 입력 버퍼를 기반으로 후보를 갱신합니다.
    ///
    /// 갱신 결과는 `delegate`의
    /// `SuggestionControllerDelegate/suggestionController(_:didUpdateCurrentWord:suggestions:)`를 통해 전달됩니다.
    ///
    /// 입력 중일 때는 button1에 현재 단어, button2~3에 자동완성 후보를 표시하고,
    /// 입력이 없거나 마지막 문자가 공백이면 n-gram 기반 다음 단어 예측을 표시합니다.
    ///
    /// - Parameters:
    ///   - baseText: 일반 자동완성을 제공할 현재 세션 텍스트
    ///   - selectedText: 후보 생성 시점에 선택된 텍스트. 선택이 없으면 `nil`
    ///   - mathExpressionText: 수식 탐지에만 사용하는 텍스트. 일반 예측 엔진과
    ///     텍스트 대치에는 전달하지 않습니다.
    func updateSuggestions(
        for baseText: String,
        selectedText: String?,
        mathExpressionText: String
    )

    /// n-gram 추천 탭 후 강제로 n-gram 갱신을 시도하고,
    /// 결과가 없으면 입력 중 모드로 폴백합니다.
    ///
    /// - Parameter inputBuffer: 현재 키보드 세션에서 직접 입력한 텍스트 버퍼
    func updateSuggestionsAfterNGramSelection(inputBuffer: String)

    /// 모든 후보를 초기화합니다.
    func clearSuggestions()

    /// 사용자가 후보를 선택했을 때 호출합니다.
    ///
    /// 현재 입력 중인 단어를 선택한 후보로 교체하기 위한 정보를 반환합니다.
    ///
    /// - Parameters:
    ///   - index: 선택된 후보의 인덱스 (0~1)
    ///   - baseText: 자동완성을 제공할 텍스트.
    ///     일반적으로 키보드 세션의 `inputBuffer`이며,
    ///     텍스트가 선택된 경우 `selectedText`가 전달될 수 있습니다.
    /// - Returns: 삭제할 글자 수와 삽입할 텍스트의 튜플, 유효하지 않으면 `nil`
    func selectSuggestion(at index: Int, baseText: String) -> (deleteCount: Int, insertText: String)?

    /// n-gram 모드에서 특정 인덱스의 후보 텍스트를 반환합니다.
    ///
    /// `selectSuggestion`은 마지막 문자가 공백일 때 `nil`을 반환하므로,
    /// n-gram 모드에서는 이 메서드로 후보를 직접 가져와 삽입합니다.
    ///
    /// - Parameter index: 선택된 후보의 인덱스 (0~2)
    /// - Returns: 후보 텍스트, 유효하지 않거나 n-gram 출처가 아니면 `nil`
    func nGramSuggestionText(at index: Int) -> String?

    /// 수식 결과 모드에서 현재 선택 텍스트를 반영한 후보 적용 action을 반환합니다.
    ///
    /// - Parameters:
    ///   - index: 선택된 후보의 인덱스 (0~2)
    ///   - selectedText: 현재 선택된 텍스트. 선택이 없으면 `nil`
    /// - Returns: 적용할 action, 유효하지 않거나 수식 후보가 아니면 `nil`
    func mathResultAction(
        at index: Int,
        selectedText: String?
    ) -> MathResultSuggestionAction?

    /// 현재 입력 버퍼가 스페이스로 텍스트 대치될 때 강조할 SuggestionBar 후보 인덱스를 반환합니다.
    ///
    /// 이 메서드는 대치 이력을 변경하지 않는 preview 용도입니다.
    ///
    /// - Parameter baseText: 텍스트 대치를 제공할 텍스트
    /// - Returns: SuggestionBar 후보 인덱스 (0~2), 대치 후보가 없으면 `nil`
    func textReplacementPreviewSuggestionIndex(baseText: String) -> Int?

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

    /// 미기록 단어를 기록한 뒤 n-gram 문장 버퍼를 초기화합니다.
    func endSentence(inputBuffer: String)

    /// n-gram 데이터를 디스크에 저장합니다.
    ///
    /// 키보드가 비활성화되기 전에 호출합니다.
    func saveNGramData()

    /// `inputBuffer`에서 아직 문장 버퍼에 기록되지 않은 단어들을 순서대로 기록합니다.
    func recordUncommittedWords(from inputBuffer: String)

    /// 마지막으로 기록된 단어를 문장 버퍼에서 제거합니다.
    func removeLastRecordedWord()

    /// 문장 버퍼를 초기화합니다.
    func resetSentenceBuffer()

    // MARK: - Text Replacement

    /// 스페이스 입력 시 텍스트 대치를 시도합니다.
    ///
    /// 입력 버퍼의 끝부분이 `UILexicon`의 `userInput`과 일치하면
    /// 해당 `documentText`로 교체합니다.
    /// 방금 복구된 단축어와 동일하면 대치를 건너뜁니다.
    ///
    /// - Parameter baseText: 텍스트 대치를 제공할 텍스트
    /// - Parameter documentContextBeforeInput: 호스트 앱이 제공하는 커서 앞 텍스트
    /// - Returns: 대치 수행 정보. 대치가 불필요하면 `nil`
    func attemptTextReplacement(
        baseText: String,
        documentContextBeforeInput: String?
    ) -> (deleteCount: Int, insertText: String)?

    /// 삭제 시 방금 수행된 텍스트 대치를 복구합니다.
    ///
    /// 입력 버퍼 또는 커서 앞 컨텍스트의 끝부분이 이전에 대치된 `documentText`와 일치하면
    /// 원래 `userInput`으로 되돌립니다.
    ///
    /// - Parameter inputBuffer: 현재 키보드 세션에서 직접 입력한 텍스트 버퍼
    /// - Parameter documentContextBeforeInput: 호스트 앱이 제공하는 커서 앞 텍스트
    /// - Parameter selectedText: 현재 선택된 텍스트. 존재하면 선택 삭제를 우선합니다.
    /// - Returns: 복구 수행 정보. 복구할 대상이 없으면 `nil`
    func attemptRestoreReplacement(
        inputBuffer: String,
        documentContextBeforeInput: String?,
        selectedText: String?
    ) -> (deleteCount: Int, insertText: String)?

    // MARK: - State Management

    /// 스페이스 이외의 키 입력 시 호출하여 재대치 방지 상태를 초기화합니다.
    func clearIgnoredShortcut()

    /// 대치 이력을 모두 초기화합니다.
    func clearReplacementHistory()
}

extension SuggestionService {
    func updateSuggestions(
        for baseText: String,
        selectedText: String?
    ) {
        updateSuggestions(
            for: baseText,
            selectedText: selectedText,
            mathExpressionText: baseText
        )
    }

    func updateSuggestions(for baseText: String) {
        updateSuggestions(for: baseText, selectedText: nil)
    }
}
