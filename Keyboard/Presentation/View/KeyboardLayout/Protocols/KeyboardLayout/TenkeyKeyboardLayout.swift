//
//  TenkeyKeyboardLayout.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/6/25.
//


/// 텐키 키보드 레이아웃 프로토콜
protocol TenkeyKeyboardLayout: BaseKeyboardLayout {
    /// 현재 텐키 키보드 레이아웃 모드
    var currentTenkeyKeyboardMode: TenkeyKeyboardMode { get set }
    /// `UIKeyboardType`이 `.default` 일 때의 레이아웃 설정
    func updateLayoutToDefault()
    /// `UIKeyboardType`이 `.numberPad` 일 때의 레이아웃 설정
    func updateLayoutToNumberPad()
    /// `UIKeyboardType`이 `.decimalPad` 일 때의 레이아웃 설정
    func updateLayoutToDecimalPad()
}
