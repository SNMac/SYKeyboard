//
//  CursorDragAccelerationPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/4/26.
//

import CoreGraphics
import Testing

@testable import SYKeyboardCore

@Suite("커서 드래그 가속 정책 검증")
struct CursorDragAccelerationPolicyTests {

    @Test("느린 드래그는 cursorMoveInterval마다 1칸 이동")
    func test느린드래그_기본간격_1칸이동() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 5,
            velocity: 25,
            previousVelocity: 20,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .right)
        #expect(result?.steps == 1)
        #expect(result?.velocity == 25)
    }

    @Test("한 업데이트에서 여러 interval이 누적되면 기본 tick이 여러 칸이 됨")
    func test여러Interval누적_기본Tick반영() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: -12,
            velocity: 60,
            previousVelocity: 55,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .left)
        #expect(result?.steps == 2)
    }

    @Test("커서 활성화 첫 이동은 활성화 누적 거리를 가속 step으로 사용하지 않음")
    func test커서활성화_첫이동_1칸() {
        let result = CursorDragAccelerationPolicy.initialMovement(
            deltaX: 40,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .right)
        #expect(result?.steps == 1)
        #expect(result?.velocity == 0)
    }

    @Test("빠른 드래그는 cursorMoveInterval 기본 tick에 속도 보정을 더함")
    func test빠른드래그_속도보정() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 10,
            velocity: 1000,
            previousVelocity: 900,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .right)
        #expect(result?.steps == 3)
    }

    @Test("650pt/s는 기본 interval에서 속도 보정을 만들지 않음")
    func test650pts_속도보정없음() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 5,
            velocity: 650,
            previousVelocity: 640,
            cursorMoveInterval: 5
        )

        #expect(result?.steps == 1)
    }

    @Test("1200pt/s는 very fast가 아니라 fast 보정만 적용")
    func test1200pts_fast보정만적용() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 5,
            velocity: 1200,
            previousVelocity: 1100,
            cursorMoveInterval: 5
        )

        #expect(result?.steps == 2)
    }

    @Test("첫 속도 측정은 가속 증가 보정을 적용하지 않음")
    func test첫속도측정_가속증가보정없음() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 5,
            velocity: 1000,
            previousVelocity: 0,
            cursorMoveInterval: 5
        )

        #expect(result?.steps == 2)
    }

    @Test("가속 구간은 추가 보정을 적용하되 최대 step을 넘지 않음")
    func test가속구간_최대Step제한() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 20,
            velocity: 2000,
            previousVelocity: 1000,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .right)
        #expect(result?.steps == CursorDragAccelerationPolicy.maximumStep)
    }

    @Test("가장 민감한 interval에서도 최대 step을 넘지 않음")
    func test민감한Interval_최대Step제한() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 8,
            velocity: 2000,
            previousVelocity: 1000,
            cursorMoveInterval: 1
        )

        #expect(result?.steps == CursorDragAccelerationPolicy.maximumStep)
    }

    @Test("방향 전환 중 interval 미만 이동은 step을 만들지 않음")
    func testInterval미만이동_이동없음() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: -4,
            velocity: -1000,
            previousVelocity: 1000,
            cursorMoveInterval: 5
        )

        #expect(result == nil)
    }

    @Test("왼쪽 커서 이동 적용 step은 요청 step과 앞 문맥 길이 중 작은 값")
    func test왼쪽커서이동_적용Step계산() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .left,
            requestedSteps: 4,
            documentContextBeforeInput: "가나",
            documentContextAfterInput: "다라마"
        )

        #expect(steps == 2)
    }

    @Test("오른쪽 커서 이동 적용 step은 요청 step과 뒤 문맥 길이 중 작은 값")
    func test오른쪽커서이동_적용Step계산() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .right,
            requestedSteps: 4,
            documentContextBeforeInput: "가나다",
            documentContextAfterInput: "라마"
        )

        #expect(steps == 2)
    }

    @Test("오른쪽 문맥이 빈 문자열이면 경계 이동을 위해 1칸 요청")
    func test오른쪽커서이동_빈문맥_1Step() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .right,
            requestedSteps: 4,
            documentContextBeforeInput: "가",
            documentContextAfterInput: ""
        )

        #expect(steps == 1)
    }

    @Test("오른쪽 문맥이 nil이면 경계 이동을 위해 1칸 요청")
    func test오른쪽커서이동_nil문맥_1Step() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .right,
            requestedSteps: 4,
            documentContextBeforeInput: "가",
            documentContextAfterInput: nil
        )

        #expect(steps == 1)
    }

    @Test("커서 이동 적용 step은 nil 문맥이면 0")
    func test커서이동_nil문맥_0Step() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .left,
            requestedSteps: 4,
            documentContextBeforeInput: nil,
            documentContextAfterInput: "라마"
        )

        #expect(steps == 0)
    }
}
