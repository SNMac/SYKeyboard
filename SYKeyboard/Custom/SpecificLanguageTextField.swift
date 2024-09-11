//
//  SpecificLanguageTextField.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/12/24.
//

import Foundation
import UIKit
import SwiftUI

class SpecificLanguageTextField: UITextField {
    var language: String? {
        didSet {
            if self.isFirstResponder{
                self.resignFirstResponder();
                self.becomeFirstResponder();
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
    @Binding var text: String
    var language: String = "en-US"

    func makeUIView(context: Context) -> UITextField {
        let textField = SpecificLanguageTextField(frame: .zero)
        textField.placeholder = self.placeHolder
        textField.text = self.text
        textField.language = self.language
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
    }
}
