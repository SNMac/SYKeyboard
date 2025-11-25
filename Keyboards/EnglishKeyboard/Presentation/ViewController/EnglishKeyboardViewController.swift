//
//  EnglishKeyboardViewController.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit
import EnglishKeyboardCore

import FirebaseCore

/// 영어 키보드 입력/UI 컨트롤러
final class EnglishKeyboardViewController: EnglishKeyboardCoreViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}
