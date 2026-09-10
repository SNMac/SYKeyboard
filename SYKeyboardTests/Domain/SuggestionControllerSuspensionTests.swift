//
//  SuggestionControllerSuspensionTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/10/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("자동완성 컨트롤러 일시 중단 전이 검증")
struct SuggestionControllerSuspensionTests {

    @Test("억제로 전환될 때만 후보를 비우고, 같은 값 재대입은 후보 갱신을 보내지 않음")
    func test억제재대입은_후보갱신을보내지않음() {
        let delegate = RecordingSuspensionDelegate()
        let controller = SuggestionController()
        controller.delegate = delegate

        controller.isSuspended = true
        #expect(delegate.updates.count == 1)
        #expect(delegate.updates.last?.currentWord == nil)
        #expect(delegate.updates.last?.suggestions == [])

        // `.no` 필드에서는 키 입력마다 같은 값이 다시 대입된다
        controller.isSuspended = true
        controller.isSuspended = true
        #expect(delegate.updates.count == 1)
    }

    @Test("억제를 해제했다가 다시 억제하면 후보를 다시 비움")
    func test억제해제후_재억제하면_후보를다시비움() {
        let delegate = RecordingSuspensionDelegate()
        let controller = SuggestionController()
        controller.delegate = delegate

        controller.isSuspended = true
        #expect(delegate.updates.count == 1)

        controller.isSuspended = false
        #expect(delegate.updates.count == 1)

        controller.isSuspended = true
        #expect(delegate.updates.count == 2)
        #expect(delegate.updates.last?.suggestions == [])
    }
}

// MARK: - Test Doubles

private final class RecordingSuspensionDelegate: SuggestionControllerDelegate {
    struct Update {
        let currentWord: String?
        let suggestions: [String]
    }

    private(set) var updates: [Update] = []

    func suggestionController(
        _ controller: SuggestionController,
        didUpdateCurrentWord currentWord: String?,
        suggestions: [String]
    ) {
        updates.append(Update(currentWord: currentWord, suggestions: suggestions))
    }
}
