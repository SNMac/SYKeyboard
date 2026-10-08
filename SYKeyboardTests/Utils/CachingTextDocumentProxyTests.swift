//
//  CachingTextDocumentProxyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("CachingTextDocumentProxy 콜백 범위 읽기 캐시")
@MainActor
struct CachingTextDocumentProxyTests {

    @Test("범위 밖에서는 읽을 때마다 프록시를 읽음")
    func testReadsProxyEveryTimeOutsideScope() {
        let proxy = CountingTextDocumentProxy()
        let textDocument = CachingTextDocumentProxy { proxy }

        _ = textDocument.documentContextBeforeInput
        _ = textDocument.documentContextBeforeInput

        #expect(proxy.readCount(of: "documentContextBeforeInput") == 2)
    }

    @Test("범위 안에서는 같은 값을 한 번만 읽음")
    func testReadsProxyOnceInsideScope() {
        let proxy = CountingTextDocumentProxy()
        proxy.keyboardType = .emailAddress
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            #expect(textDocument.documentContextBeforeInput == "안녕")
            #expect(textDocument.documentContextBeforeInput == "안녕")
            #expect(textDocument.keyboardType == .emailAddress)
            #expect(textDocument.keyboardType == .emailAddress)
        }

        #expect(proxy.readCount(of: "documentContextBeforeInput") == 1)
        #expect(proxy.readCount(of: "keyboardType") == 1)
    }

    @Test("범위 안에서 읽은 nil도 다시 읽지 않음")
    func testCachesNilInsideScope() {
        let proxy = CountingTextDocumentProxy()
        proxy.afterInput = nil
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            #expect(textDocument.documentContextAfterInput == nil)
            #expect(textDocument.documentContextAfterInput == nil)
        }

        #expect(proxy.readCount(of: "documentContextAfterInput") == 1)
    }

    @Test("범위 안에서 쓰면 다음 읽기는 쓰기가 반영된 값을 다시 읽음")
    func testWriteInsideScopeRereadsValue() {
        let proxy = CountingTextDocumentProxy()
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            #expect(textDocument.documentContextBeforeInput == "안녕")
            textDocument.deleteBackward()
            #expect(textDocument.documentContextBeforeInput == "안")
            #expect(textDocument.documentContextBeforeInput == "안")
        }

        #expect(proxy.readCount(of: "documentContextBeforeInput") == 2)
    }

    @Test("쓰기는 순서와 인자 그대로 프록시에 전달됨")
    func testForwardsWritesInOrder() {
        let proxy = CountingTextDocumentProxy()
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.insertText("가")
        textDocument.deleteBackward()
        textDocument.adjustTextPosition(byCharacterOffset: -1)

        #expect(proxy.writes == ["insertText(가)", "deleteBackward", "adjustTextPosition(-1)"])
    }

    @Test("안쪽 범위가 끝나도 바깥 범위 캐시는 남고, 바깥 범위가 끝나면 버림")
    func testNestedScopeKeepsOuterCacheUntilOutermostEnds() {
        let proxy = CountingTextDocumentProxy()
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            _ = textDocument.documentContextBeforeInput
            textDocument.withReadCaching {
                _ = textDocument.documentContextBeforeInput
            }
            _ = textDocument.documentContextBeforeInput
        }
        #expect(proxy.readCount(of: "documentContextBeforeInput") == 1)

        proxy.beforeInput = "바뀐 문맥"
        #expect(textDocument.documentContextBeforeInput == "바뀐 문맥")
        #expect(proxy.readCount(of: "documentContextBeforeInput") == 2)
    }

    @Test("문서 식별자는 KVC로 읽고 범위 안에서 한 번만 읽음")
    func testDocumentIdentifierReadsThroughKVCOnceInsideScope() {
        let proxy = CountingTextDocumentProxy()
        let identifier = UUID()
        proxy.identifier = identifier
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            #expect(textDocument.documentIdentifier == identifier)
            #expect(textDocument.documentIdentifier == identifier)
        }

        #expect(proxy.readCount(of: "documentIdentifier") == 1)
    }

    @Test("프록시가 없으면 읽기는 nil이나 false를 돌려주고 쓰기는 무시함")
    func testMissingProxyReturnsEmptyValuesAndIgnoresWrites() {
        let textDocument = CachingTextDocumentProxy { nil }

        textDocument.withReadCaching {
            #expect(textDocument.documentContextBeforeInput == nil)
            #expect(textDocument.selectedText == nil)
            #expect(textDocument.documentIdentifier == nil)
            #expect(textDocument.keyboardType == nil)
            #expect(textDocument.hasText == false)
            textDocument.insertText("가")
            textDocument.deleteBackward()
            textDocument.adjustTextPosition(byCharacterOffset: -1)
        }
        #expect(textDocument.documentContextAfterInput == nil)
    }
}
