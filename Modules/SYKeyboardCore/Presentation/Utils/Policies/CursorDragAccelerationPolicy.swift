//
//  CursorDragAccelerationPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/4/26.
//

import CoreGraphics

/// 커서 이동 드래그의 속도/가속도 기반 step 계산 정책
enum CursorDragAccelerationPolicy {

    // MARK: - Properties

    static let maximumStep: Int = 4

    private static let fastVelocityThreshold: CGFloat = 900
    private static let veryFastVelocityThreshold: CGFloat = 1600
    private static let accelerationThreshold: CGFloat = 900

    // MARK: - Types

    struct Movement {
        let direction: PanDirection
        let steps: Int
        let velocity: CGFloat
    }

    // MARK: - Internal Methods

    static func initialMovement(
        deltaX: CGFloat,
        cursorMoveInterval: CGFloat
    ) -> Movement? {
        guard cursorMoveInterval > 0 else { return nil }

        let distance = abs(deltaX)
        guard distance >= cursorMoveInterval else { return nil }

        let direction: PanDirection = deltaX > 0 ? .right : .left
        return Movement(direction: direction, steps: 1, velocity: 0)
    }

    static func movement(
        deltaX: CGFloat,
        velocity: CGFloat,
        previousVelocity: CGFloat,
        cursorMoveInterval: CGFloat
    ) -> Movement? {
        guard cursorMoveInterval > 0 else { return nil }

        let distance = abs(deltaX)
        let baseTicks = Int(distance / cursorMoveInterval)
        guard baseTicks > 0 else { return nil }

        let direction: PanDirection = deltaX > 0 ? .right : .left
        let speed = abs(velocity)
        let acceleration = speed - previousVelocity
        let steps = min(
            maximumStep,
            max(
                1,
                baseTicks
                    + speedBoost(for: speed)
                    + accelerationBoost(
                        for: acceleration,
                        previousVelocity: previousVelocity
                    )
            )
        )

        return Movement(direction: direction, steps: steps, velocity: speed)
    }

    static func applicableSteps(
        to direction: PanDirection,
        requestedSteps: Int,
        documentContextBeforeInput: String?,
        documentContextAfterInput: String?
    ) -> Int {
        guard requestedSteps > 0 else { return 0 }

        switch direction {
        case .left:
            guard let documentContextBeforeInput else { return 0 }
            return min(requestedSteps, documentContextBeforeInput.suffix(requestedSteps).count)
        case .right:
            guard let documentContextAfterInput else { return 0 }
            return min(requestedSteps, documentContextAfterInput.prefix(requestedSteps).count)
        default:
            return 0
        }
    }
}

private extension CursorDragAccelerationPolicy {
    static func speedBoost(for velocity: CGFloat) -> Int {
        if velocity >= veryFastVelocityThreshold {
            return 2
        } else if velocity >= fastVelocityThreshold {
            return 1
        } else {
            return 0
        }
    }

    static func accelerationBoost(
        for acceleration: CGFloat,
        previousVelocity: CGFloat
    ) -> Int {
        return previousVelocity > 0 && acceleration >= accelerationThreshold ? 1 : 0
    }
}
