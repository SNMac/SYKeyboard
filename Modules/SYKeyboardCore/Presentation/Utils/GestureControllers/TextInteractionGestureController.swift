//
//  TextInteractionGestureController.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/3/25.
//

import UIKit
import OSLog

protocol TextInteractionGestureControllerDelegate: AnyObject {
    func primaryButtonCursorDragActivated(_ controller: TextInteractionGestureController)
    func primaryButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection, steps: Int)
    func deleteButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection)
    func primaryButtonPanStopped(_ controller: TextInteractionGestureController)
    func deleteButtonPanStopped(_ controller: TextInteractionGestureController)
    func textInteractableButtonLongPressing(_ controller: TextInteractionGestureController, button: TextInteractable)
    func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController, button: TextInteractable)
}

/// 입력 상호작용 버튼 제스처 컨트롤러
final class TextInteractionGestureController: NSObject {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    private var isCursorActive: Bool = false
    private var initialPanPoint: CGPoint = .zero
    private var intervalReferPanPoint: CGPoint = .zero
    private var previousPanVelocity: CGFloat = 0
    private var deletePanEdgeTimer: Timer?
    private var deletePanEdgeDirection: PanDirection?
    
    // Initializer Injection
    private weak var keyboardHStackView: UIView?
    private let getCurrentPressedButton: () -> BaseKeyboardButton?
    private let setCurrentPressedButton: (BaseKeyboardButton?) -> ()
    
    // Property Injection
    weak var delegate: TextInteractionGestureControllerDelegate?
    
    // MARK: - Initializer
    
    init(keyboardHStackView: UIView,
         getCurrentPressedButton: @escaping () -> BaseKeyboardButton?,
         setCurrentPressedButton: @escaping (BaseKeyboardButton?) -> ()) {
        self.keyboardHStackView = keyboardHStackView
        self.getCurrentPressedButton = getCurrentPressedButton
        self.setCurrentPressedButton = setCurrentPressedButton
    }
    
    deinit {
        deletePanEdgeTimer?.invalidate()
        logger.debug("\(String(describing: type(of: self))) deinit")
    }
    
    // MARK: - Internal Methods
    
    func releaseButtonGesture(for button: TextInteractable) {
        setCurrentPressedButton(nil)
    }
    
    // MARK: - @objc Gesture Methods
    
    @objc func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let gestureButton = gesture.view as? TextInteractable
        let currentPoint = gesture.location(in: gesture.view)
        
        switch gesture.state {
        case .began:
            gestureButton?.isGesturing = true
            initialPanPoint = currentPoint
            intervalReferPanPoint = currentPoint
            previousPanVelocity = 0
            logger.debug("팬 제스처 활성화")
        case .changed:
            let distance = calcDistance(point1: initialPanPoint, point2: currentPoint)
            if isCursorActive || distance >= UserDefaultsManager.shared.cursorActiveDistance {
                let wasCursorActive = isCursorActive
                keyboardHStackView?.isUserInteractionEnabled = false
                
                isCursorActive = true
                gestureButton?.isGesturing = false
                if wasCursorActive {
                    onPanGestureChanged(gesture)
                } else {
                    if gesture.view is TextInteractable,
                       !(gesture.view is DeleteButton) {
                        delegate?.primaryButtonCursorDragActivated(self)
                    }
                    onPanGestureActivated(gesture)
                }
                if gesture.view is DeleteButton {
                    updateDeletePanEdgeTimer(for: gesture)
                }
            }
        case .ended, .cancelled, .failed:
            // 순서 중요
            if isCursorActive || gesture.state != .ended {
                if let gestureButton,
                   getCurrentPressedButton() === gestureButton {
                    setCurrentPressedButton(nil)
                }
            } else {
                gestureButton?.sendActions(for: .touchUpInside)
            }
            
            stopDeletePanEdgeTimer()
            onPanGestureEnded(gesture)
            isCursorActive = false
            initialPanPoint = .zero
            intervalReferPanPoint = .zero
            previousPanVelocity = 0
            gestureButton?.isGesturing = false
            
            keyboardHStackView?.isUserInteractionEnabled = true
            logger.debug("팬 제스처 비활성화")
        default:
            break
        }
    }
    
    @objc func longPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        let gestureButton = gesture.view as? TextInteractable
        
        switch gesture.state {
        case .began:
            guard getCurrentPressedButton() == gestureButton else {
                gesture.state = .cancelled
                return
            }
            keyboardHStackView?.isUserInteractionEnabled = false
            
            gestureButton?.isGesturing = true
            onLongPressGestureBegan(gesture)
            logger.debug("길게 누르기 제스처 활성화")
        case .ended, .cancelled, .failed:
            // 순서 중요
            if gesture.state == .cancelled {
                logger.debug("길게 누르기 제스처 취소")
            } else {
                setCurrentPressedButton(nil)
                logger.debug("길게 누르기 제스처 비활성화")
            }
            
            onLongPressGestureEnded(gesture)
            gestureButton?.isGesturing = false
            keyboardHStackView?.isUserInteractionEnabled = true
        default:
            break
        }
    }
}

// MARK: - Gesture Methods

private extension TextInteractionGestureController {
    func onPanGestureActivated(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: gesture.view)
        let distance = currentPoint.x - intervalReferPanPoint.x

        if let movement = CursorDragAccelerationPolicy.initialMovement(
            deltaX: distance,
            cursorMoveInterval: UserDefaultsManager.shared.cursorMoveInterval
        ) {
            if gesture.view is DeleteButton {
                delegate?.deleteButtonPanning(self, to: movement.direction)
            } else if gesture.view is TextInteractable {
                delegate?.primaryButtonPanning(self, to: movement.direction, steps: movement.steps)
            } else {
                assertionFailure("입력 상호작용 버튼이 아닙니다.")
            }
        }

        intervalReferPanPoint = currentPoint
        previousPanVelocity = 0
    }

    func onPanGestureChanged(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: gesture.view)
        
        let distance = currentPoint.x - intervalReferPanPoint.x
        if abs(distance) >= UserDefaultsManager.shared.cursorMoveInterval {
            if gesture.view is DeleteButton {
                if distance > 0 {
                    delegate?.deleteButtonPanning(self, to: .right)
                } else {
                    delegate?.deleteButtonPanning(self, to: .left)
                }
            } else if gesture.view is TextInteractable {
                if let movement = CursorDragAccelerationPolicy.movement(
                    deltaX: distance,
                    velocity: gesture.velocity(in: gesture.view).x,
                    previousVelocity: previousPanVelocity,
                    cursorMoveInterval: UserDefaultsManager.shared.cursorMoveInterval
                ) {
                    delegate?.primaryButtonPanning(self, to: movement.direction, steps: movement.steps)
                    previousPanVelocity = movement.velocity
                }
            } else {
                assertionFailure("입력 상호작용 버튼이 아닙니다.")
            }
            intervalReferPanPoint = currentPoint
        }
    }

    /// 손가락이 창 가장자리 구역에 있는 동안 삭제·복구를 반복 속도로 이어 갑니다.
    ///
    /// 베젤에 막혀 더 끌 수 없어도 손가락을 대고 있으면 계속 진행하고, 구역을 벗어나면 멈춥니다.
    func updateDeletePanEdgeTimer(for gesture: UIPanGestureRecognizer) {
        let direction = KeyboardGesturePolicy.deletePanEdgeDirection(
            locationX: gesture.location(in: nil).x,
            containerWidth: gesture.view?.window?.bounds.width ?? 0
        )
        guard direction != deletePanEdgeDirection else { return }

        stopDeletePanEdgeTimer()
        guard let direction else { return }

        deletePanEdgeDirection = direction
        let interval = KeyboardGesturePolicy.deletePanEdgeRepeatInterval(
            repeatRate: UserDefaultsManager.shared.repeatRate
        )
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self, weak gesture] _ in
            guard let self else { return }
            // 터치 없이도 발화하므로 pan이 끝났거나 키보드가 내려갔으면 스스로 멈춘다
            guard let gesture,
                  gesture.state == .began || gesture.state == .changed,
                  gesture.view?.window != nil else {
                stopDeletePanEdgeTimer()
                return
            }
            delegate?.deleteButtonPanning(self, to: direction)
        }
        RunLoop.main.add(timer, forMode: .common)
        deletePanEdgeTimer = timer
        logger.debug("삭제 pan 가장자리 반복 시작")
    }

    func stopDeletePanEdgeTimer() {
        deletePanEdgeTimer?.invalidate()
        deletePanEdgeTimer = nil
        deletePanEdgeDirection = nil
    }
    
    func onPanGestureEnded(_ gesture: UIPanGestureRecognizer) {
        if gesture.view is DeleteButton {
            delegate?.deleteButtonPanStopped(self)
        } else if isCursorActive,
                  gesture.view is TextInteractable {
            delegate?.primaryButtonPanStopped(self)
        }
    }
    
    func onLongPressGestureBegan(_ gesture: UILongPressGestureRecognizer) {
        guard let gestureButton = gesture.view as? TextInteractable else {
            assertionFailure("입력 상호작용 버튼이 아닙니다.")
            return
        }
        delegate?.textInteractableButtonLongPressing(self, button: gestureButton)
    }
    
    func onLongPressGestureEnded(_ gesture: UILongPressGestureRecognizer) {
        guard let gestureButton = gesture.view as? TextInteractable else {
            assertionFailure("입력 상호작용 버튼이 아닙니다.")
            return
        }
        delegate?.textInteractableButtonLongPressStopped(self, button: gestureButton)
    }
}

// MARK: - Gesture Helper Methods

private extension TextInteractionGestureController {
    func calcDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TextInteractionGestureController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
}
