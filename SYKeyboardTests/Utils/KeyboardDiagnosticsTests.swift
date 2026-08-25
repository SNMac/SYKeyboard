//
//  KeyboardDiagnosticsTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 8/19/26.
//

import Testing

@testable import SYKeyboardCore

/// `KeyboardDiagnostics.record`가 전역 static이라 병렬 실행 시 서로 덮어쓴다
@Suite("진단 기록 개인정보 보호", .serialized)
struct KeyboardDiagnosticsTests {

    @Test("반복 횟수는 정확한 값이 아니라 구간으로 기록된다")
    func testTickCountIsBucketed() {
        #expect(KeyboardDiagnostics.bucket(0) == "0")
        #expect(KeyboardDiagnostics.bucket(1) == "1-9")
        #expect(KeyboardDiagnostics.bucket(9) == "1-9")
        #expect(KeyboardDiagnostics.bucket(10) == "10-49")
        #expect(KeyboardDiagnostics.bucket(49) == "10-49")
        #expect(KeyboardDiagnostics.bucket(50) == "50-199")
        #expect(KeyboardDiagnostics.bucket(199) == "50-199")
        #expect(KeyboardDiagnostics.bucket(200) == "200+")
        #expect(KeyboardDiagnostics.bucket(100_000) == "200+")
    }

    @Test("서로 다른 삭제 글자 수가 같은 구간으로 묶여 길이가 드러나지 않는다")
    func testDifferentLengthsShareBucket() {
        #expect(KeyboardDiagnostics.bucket(11) == KeyboardDiagnostics.bucket(48))
        #expect(KeyboardDiagnostics.bucket(201) == KeyboardDiagnostics.bucket(9_999))
    }

    @Test("리포터 연결을 해제하면 더 이상 기록되지 않는다")
    func testNoReporterIsSafe() {
        var received: [String] = []
        KeyboardDiagnostics.record = { received.append($0) }
        KeyboardDiagnostics.log("repeatInput start")
        #expect(received == ["repeatInput start"])

        KeyboardDiagnostics.record = nil
        KeyboardDiagnostics.log("repeatInput stop")

        #expect(received == ["repeatInput start"])
    }

    @Test("연결한 리포터로 메시지가 전달된다")
    func testReporterReceivesMessage() {
        var received: [String] = []
        KeyboardDiagnostics.record = { received.append($0) }
        defer { KeyboardDiagnostics.record = nil }

        KeyboardDiagnostics.log("repeatDelete exhausted")

        #expect(received == ["repeatDelete exhausted"])
    }
}
