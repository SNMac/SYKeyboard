//
//  NextKeyboardButton.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI
import UIKit

struct NextKeyboardButton: View {
  let systemName: String
  let action: Selector
  let primary: Bool
    
  var body: some View {
    Image(systemName: systemName)
      .overlay {
        NextKeyboardButtonOverlay(action: action)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .font(.system(size: 20))
      .foregroundColor(Color(uiColor: UIColor.label))
      .background(
        primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
      )
      .clipShape(.rect(cornerRadius: 5))
  }
}

struct NextKeyboardButtonOverlay: UIViewRepresentable {
  let action: Selector
  func makeUIView(context _: Context) -> UIButton {
    let button = UIButton()
    button.addTarget(
      nil,
      action: action,
      for: .allTouchEvents)
    return button
  }

  func updateUIView(_: UIButton, context _: Context) {}
}
