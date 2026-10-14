//
//  CountingTextDocumentProxy.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import UIKit

/// 필드별 읽기 횟수와 쓰기 기록을 남기는 가짜 텍스트 프록시
///
/// 쓰기는 실제 프록시처럼 앞 문맥에 반영한다
final class CountingTextDocumentProxy: NSObject, UITextDocumentProxy {

    // MARK: - Records

    /// 프로퍼티 이름별 읽기 횟수
    private(set) var readCounts: [String: Int] = [:]
    /// 쓰기 호출 기록. 예: `"insertText(가)"`, `"deleteBackward"`, `"adjustTextPosition(-1)"`
    private(set) var writes: [String] = []

    // MARK: - Stubbed Values

    var beforeInput: String? = "안녕"
    var afterInput: String?
    var selected: String?
    var identifier = UUID()
    var inputMode: UITextInputMode?
    var stubbedHasText = true

    private var storedKeyboardType: UIKeyboardType = .default
    private var storedTextContentType: UITextContentType?
    private var storedReturnKeyType: UIReturnKeyType = .default
    private var storedEnablesReturnKeyAutomatically = false
    private var storedAutocorrectionType: UITextAutocorrectionType = .default
    private var storedAutocapitalizationType: UITextAutocapitalizationType = .sentences
    private var storedSmartQuotesType: UITextSmartQuotesType = .default
    private var storedSmartDashesType: UITextSmartDashesType = .default
    private var storedSmartInsertDeleteType: UITextSmartInsertDeleteType = .default
    /// iOS 18 타입은 저장 프로퍼티에 availability를 붙일 수 없어 raw 값으로 둔다
    private var storedMathExpressionCompletionTypeRawValue = 0

    // MARK: - UITextDocumentProxy

    var documentContextBeforeInput: String? { read(beforeInput) }
    var documentContextAfterInput: String? { read(afterInput) }
    var selectedText: String? { read(selected) }
    var documentIdentifier: UUID { read(identifier) }
    var documentInputMode: UITextInputMode? { read(inputMode) }
    var hasText: Bool { read(stubbedHasText) }

    // UITextInputTraits는 get/set 요구사항이라 접근자로 읽기를 센다
    var keyboardType: UIKeyboardType {
        get { read(storedKeyboardType) }
        set { storedKeyboardType = newValue }
    }
    var textContentType: UITextContentType? {
        get { read(storedTextContentType) }
        set { storedTextContentType = newValue }
    }
    var returnKeyType: UIReturnKeyType {
        get { read(storedReturnKeyType) }
        set { storedReturnKeyType = newValue }
    }
    var enablesReturnKeyAutomatically: Bool {
        get { read(storedEnablesReturnKeyAutomatically) }
        set { storedEnablesReturnKeyAutomatically = newValue }
    }
    var autocorrectionType: UITextAutocorrectionType {
        get { read(storedAutocorrectionType) }
        set { storedAutocorrectionType = newValue }
    }
    var autocapitalizationType: UITextAutocapitalizationType {
        get { read(storedAutocapitalizationType) }
        set { storedAutocapitalizationType = newValue }
    }
    var smartQuotesType: UITextSmartQuotesType {
        get { read(storedSmartQuotesType) }
        set { storedSmartQuotesType = newValue }
    }
    var smartDashesType: UITextSmartDashesType {
        get { read(storedSmartDashesType) }
        set { storedSmartDashesType = newValue }
    }
    var smartInsertDeleteType: UITextSmartInsertDeleteType {
        get { read(storedSmartInsertDeleteType) }
        set { storedSmartInsertDeleteType = newValue }
    }
    @available(iOS 18.0, *)
    var mathExpressionCompletionType: UITextMathExpressionCompletionType {
        get { read(UITextMathExpressionCompletionType(rawValue: storedMathExpressionCompletionTypeRawValue) ?? .default) }
        set { storedMathExpressionCompletionTypeRawValue = newValue.rawValue }
    }

    func insertText(_ text: String) {
        writes.append("insertText(\(text))")
        beforeInput = (beforeInput ?? "") + text
    }

    func deleteBackward() {
        writes.append("deleteBackward")
        beforeInput = beforeInput.map { String($0.dropLast()) }
    }

    func adjustTextPosition(byCharacterOffset offset: Int) {
        writes.append("adjustTextPosition(\(offset))")
    }

    func setMarkedText(_ markedText: String, selectedRange: NSRange) {}
    func unmarkText() {}

    // MARK: - Helpers

    func readCount(of key: String) -> Int {
        readCounts[key, default: 0]
    }

    /// 앞·뒤 문맥과 선택 텍스트 읽기 합계
    var contextReadCount: Int {
        readCount(of: "documentContextBeforeInput")
            + readCount(of: "documentContextAfterInput")
            + readCount(of: "selectedText")
    }

    func resetReadCounts() {
        readCounts.removeAll()
    }

    private func read<T>(_ value: T, key: String = #function) -> T {
        readCounts[key, default: 0] += 1
        return value
    }
}
