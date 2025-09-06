//
//  SpecificLanguageTextField.swift
//  SYKeyboard
//
//  Created by ARR on 1/31/21.
//  Edited by 서동환 on 9/12/24.
//  - Downloaded from https://stackoverflow.com/questions/65980139/how-can-i-change-the-keyboard-language-for-individual-textfields
//

import Foundation
import UIKit
import SwiftUI

class SpecificLanguageTextField: UITextField {
    var language: String? {
        didSet {
            if self.isFirstResponder{
                self.resignFirstResponder()
                self.becomeFirstResponder()
            }
        }
    }
    
    override var textInputMode: UITextInputMode? {
        if let language = self.language {
            for inputMode in UITextInputMode.activeInputModes {
                if let inputModeLanguage = inputMode.primaryLanguage, inputModeLanguage == language {
                    return inputMode
                }
            }
        }
        return super.textInputMode
    }
}

struct SpecificLanguageTextFieldView: UIViewRepresentable {
    let placeHolder: String
    var language: String = "ko-KR"
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let textField = SpecificLanguageTextField(frame: .zero)
        textField.placeholder = self.placeHolder
        textField.text = self.text
//        textField.keyboardType = .default  // 테스트용
//        textField.returnKeyType = .continue  // 테스트용
        textField.language = self.language
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {}
}
