//
//  KeyboardDiagnostics.swift
//  SYKeyboardCore
//
//  Created by Claude on 8/19/26.
//

import Foundation
#if DEBUG
import UIKit
#endif

/// 크래시 리포트에 남길 진단 기록
///
/// 키보드 확장은 비밀번호와 메시지를 포함한 사용자의 모든 입력을 볼 수 있다.
/// 따라서 이 경로로는 **입력한 텍스트, 그 일부, 정확한 길이를 절대 기록하지 않는다.**
/// 사용자 조작의 흐름과 상태 전이만 남긴다.
///
/// `SYKeyboardCore`는 Firebase에 의존하지 않으므로, 각 확장 타깃이
/// `record`에 실제 리포터를 연결한다.
public enum KeyboardDiagnostics {

    /// 확장 타깃에서 Crashlytics 같은 리포터로 연결한다
    public static var record: ((String) -> Void)?

    static func log(_ message: String) {
        record?(message)
    }

    /// 반복 횟수를 대략적인 구간 문자열로 바꾼다.
    ///
    /// 반복 삭제 tick 수는 지운 글자 수와 거의 같으므로 그대로 남기면
    /// 사용자가 입력한 길이가 기록된다. 폭주 여부만 알 수 있도록 구간으로 줄인다.
    static func bucket(_ count: Int) -> String {
        switch count {
        case ..<0: return "invalid"
        case 0: return "0"
        case 1..<10: return "1-9"
        case 10..<50: return "10-49"
        case 50..<200: return "50-199"
        default: return "200+"
        }
    }
}

// MARK: - Auto Layout 제약 충돌 기록

extension KeyboardDiagnostics {

    /// Debug 빌드에서 Auto Layout 제약 충돌을 `record`로 남기도록 설치한다.
    ///
    /// Release 빌드에서는 아무 일도 하지 않는다.
    static func installConstraintConflictLogging() {
        #if DEBUG
        _ = ConstraintConflictLogger.isInstalled
        #endif
    }
}

#if DEBUG
/// 제약 충돌 시 UIKit이 뷰에 보내는 비공개 콜백을 가로채 진단 기록에 남긴다.
///
/// 비공개 API를 쓰므로 Debug 빌드에서만 컴파일된다.
private enum ConstraintConflictLogger {

    /// 첫 접근 시 한 번만 swizzle한다. 콜백이 사라진 OS에서는 `false`를 반환하고 아무것도 하지 않는다
    static let isInstalled: Bool = {
        let originalSelector = NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:")
        let swizzledSelector = #selector(
            UIView.syk_engine(_:willBreakConstraint:dueToMutuallyExclusiveConstraints:)
        )
        guard let original = class_getInstanceMethod(UIView.self, originalSelector),
              let swizzled = class_getInstanceMethod(UIView.self, swizzledSelector) else { return false }

        method_exchangeImplementations(original, swizzled)
        return true
    }()

    /// 같은 충돌이 레이아웃 패스마다 반복되므로 요약이 같으면 한 번만 남긴다
    private static var reported = Set<String>()

    /// Crashlytics 로그는 리포트당 64KB 롤링 버퍼라, 제약 충돌이 다른 진단 기록을 밀어내지 않도록 상한을 둔다
    private static let maxReported = 30

    static func report(view: UIView, broken: NSLayoutConstraint, conflicts: [NSLayoutConstraint]) {
        // reported를 동기화하지 않으므로 레이아웃 패스(메인 스레드) 밖의 호출은 버린다
        guard Thread.isMainThread else { return }
        // 리포터가 없으면 기록할 곳이 없다. 상한만 소진하지 않도록 먼저 막는다
        guard KeyboardDiagnostics.record != nil, reported.count < maxReported else { return }

        // constraint의 기본 description에는 UILabel의 text 등 사용자 입력이 섞일 수 있으므로
        // 타입 이름과 수치만 뽑아 쓴다
        let summary = "constraint conflict in \(type(of: view)):"
            + " broke [\(describe(broken))]"
            + " among [\(conflicts.map(describe).joined(separator: " | "))]"
        guard reported.insert(summary).inserted else { return }

        KeyboardDiagnostics.log(summary)
    }

    private static func describe(_ constraint: NSLayoutConstraint) -> String {
        let first = "\(typeName(of: constraint.firstItem)).\(name(constraint.firstAttribute))"
        let second = constraint.secondItem.map {
            " \(typeName(of: $0)).\(name(constraint.secondAttribute))"
        } ?? ""
        // intrinsic content size 제약의 constant는 렌더된 사용자 텍스트의 측정값이다.
        // 정수로 줄여 문자열 지문이 남지 않게 하고, 동시에 중복 억제 키가 매번 달라지는 것도 막는다
        let constant = Int(constraint.constant.rounded())
        // UIKit이 붙이는 UIView-Encapsulated-Layout-Height 같은 identifier가 원인 파악에 가장 유용하다
        let identifier = constraint.identifier.map { " id=\($0)" } ?? ""
        return "\(first) \(name(constraint.relation))\(second)"
            + " x\(constraint.multiplier) \(constant < 0 ? "" : "+")\(constant)"
            + " @\(constraint.priority.rawValue)\(identifier)"
    }

    private static func typeName(of item: AnyObject?) -> String {
        item.map { String(describing: type(of: $0)) } ?? "nil"
    }

    // ObjC NS_ENUM은 Swift로 임포트되면 케이스명 대신 타입명(`NSLayoutAttribute`)을 출력하므로 직접 매핑한다
    private static func name(_ attribute: NSLayoutConstraint.Attribute) -> String {
        switch attribute {
        case .left: return "left"
        case .right: return "right"
        case .top: return "top"
        case .bottom: return "bottom"
        case .leading: return "leading"
        case .trailing: return "trailing"
        case .width: return "width"
        case .height: return "height"
        case .centerX: return "centerX"
        case .centerY: return "centerY"
        case .lastBaseline: return "lastBaseline"
        case .firstBaseline: return "firstBaseline"
        case .leftMargin: return "leftMargin"
        case .rightMargin: return "rightMargin"
        case .topMargin: return "topMargin"
        case .bottomMargin: return "bottomMargin"
        case .leadingMargin: return "leadingMargin"
        case .trailingMargin: return "trailingMargin"
        case .centerXWithinMargins: return "centerXWithinMargins"
        case .centerYWithinMargins: return "centerYWithinMargins"
        case .notAnAttribute: return "notAnAttribute"
        @unknown default: return "attr\(attribute.rawValue)"
        }
    }

    private static func name(_ relation: NSLayoutConstraint.Relation) -> String {
        switch relation {
        case .lessThanOrEqual: return "<="
        case .equal: return "=="
        case .greaterThanOrEqual: return ">="
        @unknown default: return "rel\(relation.rawValue)"
        }
    }
}

private extension UIView {
    @objc dynamic func syk_engine(
        _ engine: Any,
        willBreakConstraint constraint: NSLayoutConstraint,
        dueToMutuallyExclusiveConstraints constraints: [NSLayoutConstraint]
    ) {
        // swizzle 이후 원본 구현을 가리킨다
        syk_engine(engine, willBreakConstraint: constraint, dueToMutuallyExclusiveConstraints: constraints)

        ConstraintConflictLogger.report(view: self, broken: constraint, conflicts: constraints)
    }
}
#endif
