//
//  SwitchGestureHandling.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/2/25.
//

import UIKit

/// 키보드 전환 버튼 제스처 핸들러 프로토콜
public protocol SwitchGestureHandling: AnyObject {
    /// 키보드 전환 버튼
    var switchButton: SwitchButton { get }
    /// 키보드 레이아웃 선택 UI
    var keyboardSelectOverlayView: KeyboardSelectOverlayView { get }
    /// 한 손 키보드 선택 UI
    var oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView { get }
    /// `keyboardSelectOverlayView`를 표시하는 메서드
    /// - Parameters:
    ///   - needToEmphasizeTarget: `Bool`
    ///     - `true`: `KeyboardSelectOverlayView`에서 키보드 레이아웃 별로 제스처를 통해 전환될 라벨을 강조
    ///     - `false`: X 이미지를 강조
    func showKeyboardSelectOverlay(needToEmphasizeTarget: Bool)
    /// `keyboardSelectOverlayView`를 숨기는 메서드
    func hideKeyboardSelectOverlay()
    /// `OneHandedModeSelectOverlayView`를 표시하는 메서드
    /// - Parameters:
    ///   - mode: `OneHandedMode`
    ///     - `mode`에 맞는 이미지를 강조
    func showOneHandedModeSelectOverlay(of mode: OneHandedMode)
    /// `OneHandedModeSelectOverlayView`를 숨기는 메서드
    func hideOneHandedModeSelectOverlay()
    /// 모든 버튼의 터치를 활성화하는 메서드
    func enableAllButtonUserInteraction()
    /// 모든 버튼의 터치를 비활성화하는 메서드
    func disableAllButtonUserInteraction()
}

public extension SwitchGestureHandling {
    func showKeyboardSelectOverlay(needToEmphasizeTarget: Bool) {
        keyboardSelectOverlayView.configure(needToEmphasizeTarget: needToEmphasizeTarget)
        keyboardSelectOverlayView.isHidden = false
    }
    
    func hideKeyboardSelectOverlay() {
        keyboardSelectOverlayView.isHidden = true
        keyboardSelectOverlayView.resetIsEmphasizingTarget()
    }
    
    func showOneHandedModeSelectOverlay(of mode: OneHandedMode) {
        oneHandedModeSelectOverlayView.configure(emphasizeOf: mode)
        oneHandedModeSelectOverlayView.isHidden = false
    }
    
    func hideOneHandedModeSelectOverlay() {
        oneHandedModeSelectOverlayView.isHidden = true
        oneHandedModeSelectOverlayView.resetLastEmphasizeMode()
    }
}
