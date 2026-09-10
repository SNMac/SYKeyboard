//
//  ClipboardImagePolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/10/26.
//

import Foundation

/// 클립보드 이미지 항목의 저장 한도·타입·크기 규칙. UI와 파일 시스템에 의존하지 않는다
///
/// 키보드 extension은 메모리 상한이 수십 MB라 원본을 통째로 디코드하지 않는다. 한도는 캡처 전에
/// 파일 크기와 헤더의 픽셀 수만 보고 판단하고, 표시는 작은 썸네일·미리보기만 디코드한다
public enum ClipboardImagePolicy {
    /// 이미지 파일 하나의 최대 바이트. 초과하면 저장하지 않는다
    public static let maxByteSize = 12 * 1_024 * 1_024
    /// 이미지 하나의 최대 픽셀 수(가로 × 세로). 초과하면 저장하지 않는다
    // ponytail: PNG는 ImageIO가 전체 디코드할 수 있어 24 MP에서 약 96 MB 피크가 가능. 실기기에서 종료되면 PNG 전용 상한을 추가
    public static let maxPixelCount = 24_000_000
    /// 목록 행 썸네일의 긴 변 픽셀
    public static let thumbnailMaxPixelSize = 240
    /// 키보드 상세 뷰 미리보기의 긴 변 픽셀. 디코드 시 최대 약 1.4 MB
    public static let keyboardPreviewMaxPixelSize = 600
    /// 앱 원문 시트 미리보기의 긴 변 픽셀
    public static let appPreviewMaxPixelSize = 1_200
    /// 저장에 쓸 pasteboard 타입 우선순위. 작은 쪽을 먼저 고르고 TIFF·GIF 등은 받지 않는다
    public static let preferredTypeIdentifiers = ["public.jpeg", "public.heic", "public.png"]
    /// 캡처 전 남아 있어야 하는 메모리. 파일 바이트가 일시적으로 두 번 올라올 수 있는 경우와 여유분을 더한다
    public static let requiredAvailableMemory = maxByteSize * 2 + 8 * 1_024 * 1_024

    /// pasteboard 첫 항목의 타입 목록에서 저장할 타입 하나. 우선순위 앞쪽부터 고르고 없으면 `nil`
    public static func storableType(in types: [String]) -> String? {
        return preferredTypeIdentifiers.first { types.contains($0) }
    }

    /// 바이트·픽셀 한도 안인지. 0 이하 값은 저장 불가
    public static func isStorable(byteSize: Int, pixelWidth: Int, pixelHeight: Int) -> Bool {
        return byteSize > 0 && byteSize <= maxByteSize
            && pixelWidth > 0 && pixelHeight > 0
            && pixelWidth * pixelHeight <= maxPixelCount
    }

    /// `os_proc_available_memory()` 값이 캡처에 충분한지
    public static func hasEnoughMemory(available: Int) -> Bool {
        return available >= requiredAvailableMemory
    }

    /// 원본 파일 확장자. 저장 대상이 아닌 타입은 `img`
    public static func fileExtension(for typeIdentifier: String) -> String {
        switch typeIdentifier {
        case "public.jpeg": return "jpg"
        case "public.heic": return "heic"
        case "public.png": return "png"
        default: return "img"
        }
    }
}
