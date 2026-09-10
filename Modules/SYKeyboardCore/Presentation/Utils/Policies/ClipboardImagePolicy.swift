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
    /// 이미지 파일 하나의 최대 바이트. 초과하면 저장하지 않는다. 48 MP JPEG(10~20 MB)를 받기 위한 값
    public static let maxByteSize = 24 * 1_024 * 1_024
    /// 이미지 하나의 최대 픽셀 수(가로 × 세로). 타입과 무관한 저장 상한이며, 실제로 디코드할 수 있는지는
    /// `requiredDecodeMemory`와 프로세스별 고정 예산으로 판정한다
    public static let maxPixelCount = 48_000_000
    /// 목록 행 썸네일의 긴 변 픽셀
    public static let thumbnailMaxPixelSize = 240
    /// 키보드 상세 뷰 미리보기의 긴 변 픽셀. 디코드 시 최대 약 1.4 MB
    public static let keyboardPreviewMaxPixelSize = 600
    /// 앱 원문 시트 미리보기의 긴 변 픽셀
    public static let appPreviewMaxPixelSize = 1_200
    /// 저장에 쓸 pasteboard 타입 우선순위. 작은 쪽을 먼저 고르고 TIFF·GIF 등은 받지 않는다
    public static let preferredTypeIdentifiers = ["public.jpeg", "public.heic", "public.png"]
    /// JPEG·HEIC 디코드(썸네일·미리보기)에 드는 예상 메모리. ImageIO가 축소 디코드하므로 픽셀 수와 무관한 고정값이다
    public static let scaledDecodeMemory = 24 * 1_024 * 1_024
    /// HEIC를 축소 디코드로 간주하는 픽셀 상한. iPhone 기본 사진(24 MP)까지만 실측 없이 가정하고, 그 위는 PNG처럼 전체 디코드로 계산한다
    // ponytail: 실기기에서 48 MP HEIC 썸네일 생성 메모리를 계측하면 이 값을 올리거나 없앤다
    public static let heicScaledDecodeMaxPixelCount = 24_000_000
    /// PNG 전체 디코드 비트맵 위에 더하는 여유
    public static let decodeMemoryMargin = 8 * 1_024 * 1_024
    /// 키보드 extension이 이미지 하나를 디코드하는 데 쓸 수 있는 예산. 프로세스의 남은 메모리를 조회하지 않고 이 고정값으로 판정한다.
    /// iPad Pro 13" PNG 스크린샷(2752×2064, 약 22.7 MB + 여유 8 MB)까지 들어오고, MacBook Pro 16"(약 39 MB)은 키보드에서 건너뛴다
    // ponytail: 실기기 계측에서 이 예산의 디코드가 키보드를 종료시키면 값을 낮춘다
    public static let keyboardDecodeMemoryBudget = 32 * 1_024 * 1_024
    /// 앱 프로세스의 디코드 예산. 키보드가 건너뛴 큰 PNG를 앱이 활성화될 때 대신 저장한다
    public static let appDecodeMemoryBudget = 256 * 1_024 * 1_024

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

    /// 이 이미지를 디코드(썸네일·미리보기)할 때 드는 예상 메모리.
    /// PNG는 ImageIO가 축소 디코드를 못 해 원본 전체 비트맵(픽셀 × 채널당 바이트 × 4)이 잡히므로 픽셀 수에 비례하고,
    /// JPEG와 `heicScaledDecodeMaxPixelCount` 이하 HEIC는 축소 디코드라 고정값이다. `bitDepth`는 채널당 비트(16비트 PNG는 8바이트/픽셀)
    public static func requiredDecodeMemory(typeIdentifier: String, pixelWidth: Int, pixelHeight: Int, bitDepth: Int = 8) -> Int {
        let pixelCount = pixelWidth * pixelHeight
        switch typeIdentifier {
        case "public.jpeg":
            return scaledDecodeMemory
        case "public.heic" where pixelCount <= heicScaledDecodeMaxPixelCount:
            return scaledDecodeMemory
        default:
            return pixelCount * (bitDepth > 8 ? 8 : 4) + decodeMemoryMargin
        }
    }

    /// 이 이미지의 예상 디코드 메모리가 `budget` 안에 드는지. 키보드는 `keyboardDecodeMemoryBudget`, 앱은 `appDecodeMemoryBudget`
    public static func canDecode(typeIdentifier: String, pixelWidth: Int, pixelHeight: Int, bitDepth: Int = 8, budget: Int) -> Bool {
        return requiredDecodeMemory(typeIdentifier: typeIdentifier, pixelWidth: pixelWidth, pixelHeight: pixelHeight, bitDepth: bitDepth) <= budget
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
