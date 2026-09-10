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

    @Test("바이트 한도는 24 MB까지, JPEG·HEIC 픽셀 한도는 48,000,000까지 저장 가능")
    func test바이트픽셀한도_경계값() {
        let bytes = ClipboardImagePolicy.maxByteSize
        #expect(bytes == 24 * 1_024 * 1_024)
        #expect(ClipboardImagePolicy.maxPixelCount == 48_000_000)
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes, pixelWidth: 6_000, pixelHeight: 8_000, typeIdentifier: "public.jpeg"))
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes, pixelWidth: 6_000, pixelHeight: 8_000, typeIdentifier: "public.heic"))
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes + 1, pixelWidth: 100, pixelHeight: 100, typeIdentifier: "public.jpeg") == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 6_000, pixelHeight: 8_001, typeIdentifier: "public.jpeg") == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 0, pixelWidth: 1, pixelHeight: 1, typeIdentifier: "public.jpeg") == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 0, pixelHeight: 1, typeIdentifier: "public.jpeg") == false)
    }

    @Test("PNG는 전체 디코드 위험 때문에 12,000,000픽셀까지만 저장 가능")
    func testPNG픽셀한도_경계값() {
        #expect(ClipboardImagePolicy.maxPNGPixelCount == 12_000_000)
        #expect(ClipboardImagePolicy.maxPixelCount(for: "public.png") == 12_000_000)
        #expect(ClipboardImagePolicy.maxPixelCount(for: "public.jpeg") == 48_000_000)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 3_000, pixelHeight: 4_000, typeIdentifier: "public.png"))
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 3_000, pixelHeight: 4_001, typeIdentifier: "public.png") == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 3_000, pixelHeight: 4_001, typeIdentifier: "public.jpeg"))
    }

    @Test("남은 메모리가 디코드 여유 24 MB 이상일 때만 캡처·미리보기 디코드")
    func test메모리여유판정() {
        let required = 24 * 1_024 * 1_024
        #expect(ClipboardImagePolicy.requiredAvailableMemory == required)
        #expect(ClipboardImagePolicy.hasEnoughMemory(available: required))
        #expect(ClipboardImagePolicy.hasEnoughMemory(available: required - 1) == false)
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
