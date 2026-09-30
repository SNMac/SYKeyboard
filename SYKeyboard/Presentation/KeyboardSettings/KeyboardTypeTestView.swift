//
//  KeyboardTypeTestView.swift
//  SYKeyboard
//
//  Created by Claude on 9/21/26.
//

#if DEBUG
import SwiftUI

/// `UIKeyboardType`별로 키보드가 어떻게 나오는지 확인하는 개발용 화면.
///
/// 시스템 키보드의 자판 배열을 SY키보드와 대조할 때 쓴다. 시스템 키보드를 보려면
/// 지구본 버튼으로 전환한다
struct KeyboardTypeTestView: View {

    // MARK: - Properties

    /// 확인할 키보드 타입. 표시 이름은 코드와 바로 대조할 수 있게 케이스 이름을 그대로 쓴다.
    /// `alphabet`은 `asciiCapable`과 같은 값인 deprecated 별칭이라 뺐다
    private static let keyboardTypes: [(name: String, type: UIKeyboardType)] = [
        ("default", .default),
        ("asciiCapable", .asciiCapable),
        ("numbersAndPunctuation", .numbersAndPunctuation),
        ("URL", .URL),
        ("numberPad", .numberPad),
        ("phonePad", .phonePad),
        ("namePhonePad", .namePhonePad),
        ("emailAddress", .emailAddress),
        ("decimalPad", .decimalPad),
        ("twitter", .twitter),
        ("webSearch", .webSearch),
        ("asciiCapableNumberPad", .asciiCapableNumberPad)
    ]

    // MARK: - Content

    var body: some View {
        List {
            ForEach(Self.keyboardTypes, id: \.name) { keyboardType in
                KeyboardTypeTestRow(name: keyboardType.name, type: keyboardType.type)
            }
        }
        .navigationTitle("키보드 타입 확인")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - KeyboardTypeTestRow

/// 키보드 타입 하나를 확인하는 입력칸.
///
/// 자동 대문자·자동 수정 같은 수식어를 붙이지 않는다. 그 타입의 기본 동작을 그대로 봐야 하기 때문이다
private struct KeyboardTypeTestRow: View {

    // MARK: - Properties

    let name: String
    let type: UIKeyboardType

    @State private var text = ""

    // MARK: - Content

    var body: some View {
        Section {
            TextField("입력해 보세요", text: $text)
                .keyboardType(type)
        } header: {
            Text(name)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        KeyboardTypeTestView()
    }
}
#endif
