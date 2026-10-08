//
//  CachingTextDocumentProxy.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit

/// 텍스트 프록시 읽기·쓰기 창구. 콜백 한 번 동안 같은 값을 다시 읽지 않게 한다
///
/// UIKit이 XPC 스레드에서 문서 상태를 교체하는 순간 메인 스레드가 프록시를 읽으면 크래시한다.
/// `withReadCaching(_:)` 안에서는 값마다 처음 한 번만 프록시를 읽고, 쓰기 메서드가 저장한 값을 모두 버려
/// 쓰기 뒤에는 새 값을 읽는다. 범위 밖에서는 프록시를 그대로 읽고 쓴다.
///
/// > 쓰기가 캐시를 비우도록 프록시 읽기·쓰기는 이 타입으로만 한다
@MainActor
public final class CachingTextDocumentProxy {

    // MARK: - Properties

    private let proxy: () -> any UITextDocumentProxy
    /// 중첩된 `withReadCaching(_:)` 깊이. 0이면 캐시를 쓰지 않는다
    private var cachingDepth = 0
    /// 프로퍼티 이름별로 읽은 값. `nil`도 읽은 값으로 저장한다
    private var cachedValues: [String: Any] = [:]

    // MARK: - Initializer

    init(proxy: @escaping () -> any UITextDocumentProxy) {
        self.proxy = proxy
    }

    // MARK: - Caching Scope

    /// `body`가 도는 동안 읽은 값을 저장해 다시 읽지 않습니다.
    ///
    /// 중첩할 수 있고, 가장 바깥 범위가 끝날 때 저장한 값을 버립니다
    public func withReadCaching(_ body: () -> Void) {
        cachingDepth += 1
        defer {
            cachingDepth -= 1
            if cachingDepth == 0 { cachedValues.removeAll() }
        }
        body()
    }

    // MARK: - Document

    public var documentContextBeforeInput: String? { cached { $0.documentContextBeforeInput } }
    public var documentContextAfterInput: String? { cached { $0.documentContextAfterInput } }
    public var selectedText: String? { cached { $0.selectedText } }
    public var documentInputMode: UITextInputMode? { cached { $0.documentInputMode } }
    public var hasText: Bool { cached { $0.hasText } }

    /// 헤더는 nonnull이지만 키보드가 처음 뜰 때나 입력창이 바뀌는 순간 nil이 온다.
    /// Swift 프로퍼티로 읽으면 `UUID` 브리징에서 크래시하므로 KVC로 읽는다
    public var documentIdentifier: UUID? {
        cached { ($0 as AnyObject).value(forKey: "documentIdentifier") as? UUID }
    }

    // MARK: - Input Traits

    public var keyboardType: UIKeyboardType? { cached { $0.keyboardType } }
    public var textContentType: UITextContentType? { cached { $0.textContentType ?? nil } }
    public var returnKeyType: UIReturnKeyType? { cached { $0.returnKeyType } }
    public var enablesReturnKeyAutomatically: Bool? { cached { $0.enablesReturnKeyAutomatically } }
    public var autocorrectionType: UITextAutocorrectionType? { cached { $0.autocorrectionType } }
    public var autocapitalizationType: UITextAutocapitalizationType? { cached { $0.autocapitalizationType } }
    public var smartQuotesType: UITextSmartQuotesType? { cached { $0.smartQuotesType } }
    public var smartDashesType: UITextSmartDashesType? { cached { $0.smartDashesType } }
    public var smartInsertDeleteType: UITextSmartInsertDeleteType? { cached { $0.smartInsertDeleteType } }

    @available(iOS 18.0, *)
    public var mathExpressionCompletionType: UITextMathExpressionCompletionType? {
        cached { $0.mathExpressionCompletionType }
    }

    // MARK: - Writes

    public func insertText(_ text: String) {
        cachedValues.removeAll()
        proxy().insertText(text)
    }

    public func deleteBackward() {
        cachedValues.removeAll()
        proxy().deleteBackward()
    }

    public func adjustTextPosition(byCharacterOffset offset: Int) {
        cachedValues.removeAll()
        proxy().adjustTextPosition(byCharacterOffset: offset)
    }
}

// MARK: - Private Methods

private extension CachingTextDocumentProxy {
    func cached<T>(_ key: String = #function, _ read: (any UITextDocumentProxy) -> T) -> T {
        guard cachingDepth > 0 else { return read(proxy()) }
        if let stored = cachedValues[key], let value = stored as? T { return value }

        let value = read(proxy())
        cachedValues[key] = value
        return value
    }
}
