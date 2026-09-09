//
//  KeyboardDiagnosticsTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 8/19/26.
//

import Testing
import UIKit

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

    /// swizzle은 프로세스 전역이라 다른 suite의 뷰 충돌도 `record`로 들어온다. 전용 타입으로 걸러낸다
    /// `reported`는 프로세스에 남으므로 테스트마다 서로 다른 타입을 쓴다
    private final class DedupeProbeView: UIView {}
    private final class FirstConflictProbeView: UIView {}
    private final class SecondConflictProbeView: UIView {}

    /// 폭이 서로 다른 두 제약을 걸어 충돌을 만든다
    @MainActor
    private func makeConflict(in container: UIView) {
        let label = UILabel()
        label.text = "비밀번호1234"
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: 10),
            label.widthAnchor.constraint(equalToConstant: 20)
        ])
        container.layoutIfNeeded()
    }

    @Test("제약 충돌은 사용자 입력 없이 한 번만 기록된다")
    @MainActor
    func testConstraintConflictIsLoggedOnce() {
        var received: [String] = []
        KeyboardDiagnostics.record = { received.append($0) }
        defer { KeyboardDiagnostics.record = nil }
        KeyboardDiagnostics.installConstraintConflictLogging()

        // 같은 충돌을 실제로 두 번 일으켜야 중복 억제가 검증된다.
        // 제약이 그대로인 두 번째 레이아웃 패스는 엔진이 재해결하지 않아 콜백이 오지 않는다.
        // 충돌마다 콜백이 온다는 전제는 testEachConflictIsReported가 고정한다
        for _ in 0..<2 {
            makeConflict(in: DedupeProbeView(frame: CGRect(x: 0, y: 0, width: 100, height: 100)))
        }

        let mine = received.filter { $0.contains("in DedupeProbeView") }
        let logged = mine.first ?? "(없음)"
        #expect(mine.count == 1, "기록: \(received)")
        #expect(logged.contains("constraint conflict"), "기록: \(logged)")
        #expect(logged.contains("UILabel.width"), "기록: \(logged)")
        #expect(!logged.contains("비밀번호"), "기록: \(logged)")
    }

    @Test("서로 다른 충돌은 각각 기록된다")
    @MainActor
    func testEachConflictIsReported() {
        var received: [String] = []
        KeyboardDiagnostics.record = { received.append($0) }
        defer { KeyboardDiagnostics.record = nil }
        KeyboardDiagnostics.installConstraintConflictLogging()

        makeConflict(in: FirstConflictProbeView(frame: CGRect(x: 0, y: 0, width: 100, height: 100)))
        makeConflict(in: SecondConflictProbeView(frame: CGRect(x: 0, y: 0, width: 100, height: 100)))

        #expect(received.contains { $0.contains("in FirstConflictProbeView") }, "기록: \(received)")
        #expect(received.contains { $0.contains("in SecondConflictProbeView") }, "기록: \(received)")
    }
}
