//
//  SwitchButtonGestureHandler.swift
//  Keyboard
//
//  Created by 서동환 on 9/2/25.
//

protocol SwitchButtonGestureHandler: AnyObject {
    var switchButton: SwitchButton { get }
    var keyboardSelectOverlayView: KeyboardSelectOverlayView { get }
    var oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView { get }
    func showKeyboardSelectOverlay(needToEmphasizeTarget: Bool)
    func hideKeyboardSelectOverlay()
    func showOneHandedModeSelectOverlay(of mode: OneHandedMode)
    func hideOneHandedModeSelectOverlay()
}
