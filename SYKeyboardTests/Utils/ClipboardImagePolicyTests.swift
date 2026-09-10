//
//  ClipboardImagePolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/10/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 이미지 저장 정책 검증")
struct ClipboardImagePolicyTests {

    @Test("타입 우선순위는 JPEG, HEIC, PNG 순이고 TIFF·GIF만 있으면 nil")
    func test타입우선순위() {
        #expect(ClipboardImagePolicy.storableType(in: ["public.png", "public.jpeg"]) == "public.jpeg")
        #expect(ClipboardImagePolicy.storableType(in: ["public.png", "public.heic"]) == "public.heic")
        #expect(ClipboardImagePolicy.storableType(in: ["public.tiff", "public.png"]) == "public.png")
        #expect(ClipboardImagePolicy.storableType(in: ["public.tiff", "com.compuserve.gif"]) == nil)
        #expect(ClipboardImagePolicy.storableType(in: []) == nil)
    }

    @Test("바이트 한도는 24 MB까지, 픽셀 한도는 타입과 무관하게 48,000,000까지 저장 가능")
    func test바이트픽셀한도_경계값() {
        let bytes = ClipboardImagePolicy.maxByteSize
        #expect(bytes == 24 * 1_024 * 1_024)
        #expect(ClipboardImagePolicy.maxPixelCount == 48_000_000)
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes, pixelWidth: 6_000, pixelHeight: 8_000))
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes + 1, pixelWidth: 100, pixelHeight: 100) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 6_000, pixelHeight: 8_001) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 0, pixelWidth: 1, pixelHeight: 1) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 0, pixelHeight: 1) == false)
    }

    @Test("PNG 디코드 메모리는 픽셀 × 4바이트 + 여유이고, JPEG·HEIC는 고정 24 MB")
    func test디코드메모리_타입별() {
        let margin = ClipboardImagePolicy.decodeMemoryMargin
        #expect(margin == 8 * 1_024 * 1_024)
        // iPad Pro 13" 스크린샷 2752×2064 ≈ 22.7 MB + 여유
        let ipad = ClipboardImagePolicy.requiredDecodeMemory(typeIdentifier: "public.png", pixelWidth: 2_752, pixelHeight: 2_064)
        #expect(ipad == 2_752 * 2_064 * 4 + margin)
        #expect(ClipboardImagePolicy.requiredDecodeMemory(typeIdentifier: "public.jpeg", pixelWidth: 8_000, pixelHeight: 6_000) == ClipboardImagePolicy.scaledDecodeMemory)
        #expect(ClipboardImagePolicy.requiredDecodeMemory(typeIdentifier: "public.heic", pixelWidth: 8_000, pixelHeight: 6_000) == ClipboardImagePolicy.scaledDecodeMemory)
        #expect(ClipboardImagePolicy.scaledDecodeMemory == 24 * 1_024 * 1_024)
    }

    @Test("키보드 예산 32 MB는 iPad Pro 13\" PNG 스크린샷은 받고 MacBook Pro 16\" PNG는 건너뛰며, 앱 예산은 둘 다 받음")
    func test디코드예산_기기별() {
        let keyboard = ClipboardImagePolicy.keyboardDecodeMemoryBudget
        let app = ClipboardImagePolicy.appDecodeMemoryBudget
        #expect(keyboard == 32 * 1_024 * 1_024)
        #expect(ClipboardImagePolicy.canDecode(typeIdentifier: "public.png", pixelWidth: 2_752, pixelHeight: 2_064, budget: keyboard))
        #expect(ClipboardImagePolicy.canDecode(typeIdentifier: "public.png", pixelWidth: 3_456, pixelHeight: 2_234, budget: keyboard) == false)
        #expect(ClipboardImagePolicy.canDecode(typeIdentifier: "public.png", pixelWidth: 3_456, pixelHeight: 2_234, budget: app))
        // JPEG·HEIC는 축소 디코드라 48 MP도 키보드 예산 안
        #expect(ClipboardImagePolicy.canDecode(typeIdentifier: "public.jpeg", pixelWidth: 8_000, pixelHeight: 6_000, budget: keyboard))
        #expect(ClipboardImagePolicy.canDecode(typeIdentifier: "public.jpeg", pixelWidth: 8_000, pixelHeight: 6_000, budget: ClipboardImagePolicy.scaledDecodeMemory - 1) == false)
    }

    @Test("원본 파일 확장자는 타입에서 유도")
    func test확장자유도() {
        #expect(ClipboardImagePolicy.fileExtension(for: "public.jpeg") == "jpg")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.heic") == "heic")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.png") == "png")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.tiff") == "img")
    }

    @Test("썸네일·미리보기 픽셀 크기는 키보드 메모리에 맞게 작다")
    func test썸네일미리보기크기() {
        #expect(ClipboardImagePolicy.thumbnailMaxPixelSize == 240)
        #expect(ClipboardImagePolicy.keyboardPreviewMaxPixelSize == 600)
        #expect(ClipboardImagePolicy.appPreviewMaxPixelSize == 1_200)
    }
}
