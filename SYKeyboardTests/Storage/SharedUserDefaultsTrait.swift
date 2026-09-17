//
//  SharedUserDefaultsTrait.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/18/26.
//

import Testing

/// 실제 App Group `UserDefaults`를 읽고 쓰는 suite에 붙인다.
/// `.serialized`는 suite 안에서만 순서를 보장하므로, 서로 다른 suite가 같은 키를 동시에 지우고 쓰는 것을
/// 프로세스 전역 잠금으로 막는다. suite 단계에서는 잠그지 않고 test case마다 잠근다(suite가 잡으면 자식이 대기해 교착)
struct SharedUserDefaultsTrait: SuiteTrait, TestTrait, TestScoping {
    var isRecursive: Bool { true }

    func scopeProvider(for test: Test, testCase: Test.Case?) -> SharedUserDefaultsTrait? {
        testCase == nil ? nil : self
    }

    func provideScope(
        for test: Test, testCase: Test.Case?, performing function: @concurrent @Sendable () async throws -> Void
    ) async throws {
        await SharedUserDefaultsLock.shared.acquire()
        do {
            try await function()
        } catch {
            await SharedUserDefaultsLock.shared.release()
            throw error
        }
        await SharedUserDefaultsLock.shared.release()
    }
}

extension Trait where Self == SharedUserDefaultsTrait {
    static var sharedUserDefaults: Self { Self() }
}

/// await 가능한 단순 mutex. 대기자는 FIFO로 잠금을 넘겨받는다
private actor SharedUserDefaultsLock {
    static let shared = SharedUserDefaultsLock()
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        guard isLocked else {
            isLocked = true
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    func release() {
        guard !waiters.isEmpty else {
            isLocked = false
            return
        }
        waiters.removeFirst().resume()
    }
}
